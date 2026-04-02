import Foundation
import UniformTypeIdentifiers

/// File system helper utilities
class FileHelper {
    static let shared = FileHelper()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - File Info
    
    func fileSize(at url: URL) -> Int64? {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path) else {
            return nil
        }
        return attributes[.size] as? Int64
    }
    
    func formattedFileSize(at url: URL) -> String {
        guard let size = fileSize(at: url) else {
            return "Unknown"
        }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    func creationDate(at url: URL) -> Date? {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path) else {
            return nil
        }
        return attributes[.creationDate] as? Date
    }
    
    func modificationDate(at url: URL) -> Date? {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path) else {
            return nil
        }
        return attributes[.modificationDate] as? Date
    }
    
    // MARK: - File Type
    
    func contentType(of url: URL) -> UTType? {
        return try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
    }
    
    func isImage(_ url: URL) -> Bool {
        guard let type = contentType(of: url) else { return false }
        return type.conforms(to: .image)
    }
    
    func isVideo(_ url: URL) -> Bool {
        guard let type = contentType(of: url) else { return false }
        return type.conforms(to: .movie)
    }
    
    func isPDF(_ url: URL) -> Bool {
        guard let type = contentType(of: url) else { return false }
        return type.conforms(to: .pdf)
    }
    
    func isAudio(_ url: URL) -> Bool {
        guard let type = contentType(of: url) else { return false }
        return type.conforms(to: .audio)
    }
    
    // MARK: - Operations
    
    func copy(from source: URL, to destination: URL) throws {
        try fileManager.copyItem(at: source, to: destination)
    }
    
    func move(from source: URL, to destination: URL) throws {
        try fileManager.moveItem(at: source, to: destination)
    }
    
    func delete(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }
    
    func exists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }
    
    // MARK: - Directory
    
    func createDirectory(at url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
    
    func contentsOfDirectory(at url: URL) throws -> [URL] {
        return try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .contentTypeKey],
            options: [.skipsHiddenFiles]
        )
    }
    
    func directorySize(at url: URL) -> Int64 {
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }
        
        return totalSize
    }
    
    // MARK: - Temporary
    
    func createTemporaryFile(content: String, extension ext: String = "txt") throws -> URL {
        let tempDir = fileManager.temporaryDirectory
        let filename = "\(UUID().uuidString).\(ext)"
        let url = tempDir.appendingPathComponent(filename)
        
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    func createTemporaryDirectory() throws -> URL {
        let tempDir = fileManager.temporaryDirectory
        let dirName = UUID().uuidString
        let url = tempDir.appendingPathComponent(dirName)
        
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
