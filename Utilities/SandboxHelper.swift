import Foundation
import AppKit
import os

/// Sandbox helper for secure file access
class SandboxHelper {
    static let shared = SandboxHelper()
    
    private init() {}
    
    // MARK: - File Access
    
    func requestFileAccess(for url: URL, completion: @escaping (Bool, URL?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.directoryURL = url
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Please grant access to this location"
        
        openPanel.begin { response in
            if response == .OK, let selectedURL = openPanel.url {
                completion(true, selectedURL)
            } else {
                completion(false, nil)
            }
        }
    }
    
    func requestDirectoryAccess(for url: URL, completion: @escaping (Bool, URL?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.directoryURL = url
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Please grant access to this directory"
        
        openPanel.begin { response in
            if response == .OK, let selectedURL = openPanel.url {
                completion(true, selectedURL)
            } else {
                completion(false, nil)
            }
        }
    }
    
    // MARK: - Security-Scoped Bookmarks
    
    func createBookmark(for url: URL) throws -> Data {
        return try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }
    
    func resolveBookmark(_ bookmarkData: Data) throws -> URL {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        
        if isStale {
            let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "SandboxHelper")
            logger.warning("Bookmark is stale: \(url.path, privacy: .public)")
        }
        
        return url
    }
    
    func accessSecurityScopedResource<T>(
        _ url: URL,
        handler: () throws -> T
    ) rethrows -> T {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        return try handler()
    }
    
    // MARK: - Entitlements Check
    
    func hasFileAccess(to url: URL) -> Bool {
        return FileManager.default.isReadableFile(atPath: url.path)
    }
    
    func isAppSandboxed() -> Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }
    
    // MARK: - Temporary Files
    
    func createTemporaryFile(withExtension ext: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "\(UUID().uuidString).\(ext)"
        return tempDir.appendingPathComponent(filename)
    }
    
    func createTemporaryDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let dirName = UUID().uuidString
        let dirURL = tempDir.appendingPathComponent(dirName)
        
        try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
        return dirURL
    }
    
    func cleanTemporaryFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: tempDir,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            let cutoffDate = Calendar.current.date(byAdding: .hour, value: -24, to: Date())!
            
            for fileURL in contents {
                if let creationDate = try? fileURL.resourceValues(forKeys: [.creationDateKey]).creationDate,
                   creationDate < cutoffDate {
                    try? FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch {
            let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "SandboxHelper")
            logger.error("Failed to clean temporary files: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    // MARK: - Application Support
    
    func applicationSupportDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent(AppInfo.shared.appName)
        
        if !FileManager.default.fileExists(atPath: appDir.path) {
            try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        }
        
        return appDir
    }
    
    func cacheDirectory() -> URL {
        let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let appCache = cache.appendingPathComponent(AppInfo.shared.appName)
        
        if !FileManager.default.fileExists(atPath: appCache.path) {
            try? FileManager.default.createDirectory(at: appCache, withIntermediateDirectories: true)
        }
        
        return appCache
    }
    
    // MARK: - File Operations
    
    func copyFile(from source: URL, to destination: URL) throws {
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: source, to: destination)
    }
    
    func moveFile(from source: URL, to destination: URL) throws {
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: source, to: destination)
    }
    
    func deleteFile(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
    
    // MARK: - Validation
    
    func validateFileAccess(for url: URL) -> ValidationResult {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .failure(.fileNotFound)
        }
        
        // Check if readable
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            return .failure(.noReadPermission)
        }
        
        // Check if writable (if needed)
        guard FileManager.default.isWritableFile(atPath: url.path) else {
            return .warning(.noWritePermission)
        }
        
        return .success
    }
    
    enum ValidationResult {
        case success
        case warning(ValidationError)
        case failure(ValidationError)
    }
    
    enum ValidationError: Error {
        case fileNotFound
        case noReadPermission
        case noWritePermission
        case invalidPath
        
        var localizedDescription: String {
            switch self {
            case .fileNotFound: return "File not found"
            case .noReadPermission: return "No read permission"
            case .noWritePermission: return "No write permission"
            case .invalidPath: return "Invalid file path"
            }
        }
    }
}
