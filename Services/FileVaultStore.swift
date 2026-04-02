import Foundation
import Combine
import AppKit
import UniformTypeIdentifiers
import OSLog

// MARK: - File Kind (for grouping)

enum FileKind: String, CaseIterable {
    case image
    case pdf
    case other
    
    var displayName: String {
        switch self {
        case .image: return "Images"
        case .pdf: return "PDFs"
        case .other: return "Other Files"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .image: return 0
        case .pdf: return 1
        case .other: return 2
        }
    }
    
    static func from(extension ext: String) -> FileKind {
        let lowercased = ext.lowercased()
        
        // Images
        if ["png", "jpg", "jpeg", "gif", "heic", "heif", "webp", "tiff", "tif", "bmp", "svg", "ico", "icns"].contains(lowercased) {
            return .image
        }
        
        // PDFs
        if lowercased == "pdf" {
            return .pdf
        }
        
        return .other
    }
    
    static func from(url: URL) -> FileKind {
        // Try UTType first (more accurate)
        if let utType = UTType(filenameExtension: url.pathExtension) {
            if utType.conforms(to: .image) {
                return .image
            }
            if utType.conforms(to: .pdf) {
                return .pdf
            }
        }
        
        // Fallback to extension
        return from(extension: url.pathExtension)
    }
}

/// File Vault Store - manages temporary file references with security-scoped bookmarks
/// Apple-grade persistence: survives app restarts, handles moved/missing files gracefully
final class FileVaultStore: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var files: [VaultFile] = []
    @Published var selectedFileID: UUID? = nil
    @Published var lastAddedCount: Int = 0  // For toast: "Saved N file(s)"
    
    private let logger = os.Logger(subsystem: "com.maclingdonggao.overlay", category: "file_vault")
    
    /// Collapsed section state (persisted)
    @Published var collapsedSections: Set<FileKind> = []
    private let collapsedSectionsKey = "file_vault_collapsed_sections"
    
    // MARK: - Configuration
    
    static let maxStoredFiles = 20
    private let persistenceKey = "file_vault_bookmarks_v2"
    
    // MARK: - Vault File Model
    
    struct VaultFile: Identifiable {
        let id: UUID
        let bookmarkData: Data
        let displayName: String
        let fileExtension: String
        let savedAt: Date
        var isPinned: Bool
        
        // Resolved state (not persisted)
        private(set) var resolvedURL: URL?
        private(set) var isStale: Bool = false
        
        init(url: URL, isPinned: Bool = false) {
            self.id = UUID()
            self.displayName = url.lastPathComponent
            self.fileExtension = url.pathExtension
            self.savedAt = Date()
            self.isPinned = isPinned
            
            // Create security-scoped bookmark
            do {
                self.bookmarkData = try url.bookmarkData(
                    options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                self.resolvedURL = url
                self.isStale = false
            } catch {
                // Fallback: store minimal bookmark (may fail on next launch)
                self.bookmarkData = (try? url.bookmarkData()) ?? Data()
                self.resolvedURL = url
                self.isStale = false
            }
        }
        
        // Codable-compatible initializer for persistence
        init(id: UUID, bookmarkData: Data, displayName: String, fileExtension: String, savedAt: Date, isPinned: Bool) {
            self.id = id
            self.bookmarkData = bookmarkData
            self.displayName = displayName
            self.fileExtension = fileExtension
            self.savedAt = savedAt
            self.isPinned = isPinned
            self.resolvedURL = nil
            self.isStale = true
        }
        
        var fileName: String { displayName }
        
        var fileExists: Bool {
            guard let url = resolvedURL else { return false }
            return FileManager.default.fileExists(atPath: url.path)
        }
        
        var isMissing: Bool {
            resolvedURL == nil || isStale || !fileExists
        }
        
        var path: String {
            resolvedURL?.path ?? ""
        }
        
        var fileSize: String? {
            guard let url = resolvedURL,
                  let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let size = attrs[.size] as? Int64 else {
                return nil
            }
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
        
        var icon: NSImage {
            if let url = resolvedURL, fileExists {
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                icon.size = NSSize(width: 32, height: 32)
                return icon
            } else {
                // Use modern UTType API
                let icon: NSImage
                if let utType = UTType(filenameExtension: fileExtension) {
                    icon = NSWorkspace.shared.icon(for: utType)
                } else {
                    icon = NSWorkspace.shared.icon(for: .data)
                }
                icon.size = NSSize(width: 32, height: 32)
                return icon
            }
        }
        
        var formattedTime: String {
            let calendar = Calendar.current
            let formatter = DateFormatter()
            
            if calendar.isDateInToday(savedAt) {
                formatter.dateFormat = "HH:mm"
                return "Today \(formatter.string(from: savedAt))"
            } else if calendar.isDateInYesterday(savedAt) {
                formatter.dateFormat = "HH:mm"
                return "Yesterday \(formatter.string(from: savedAt))"
            } else {
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                return formatter.string(from: savedAt)
            }
        }
        
        var fileKind: FileKind {
            if let url = resolvedURL {
                return FileKind.from(url: url)
            }
            return FileKind.from(extension: fileExtension)
        }
        
        var dragItem: URL {
            if let url = resolvedURL, fileExists {
                return url
            }
            return URL(fileURLWithPath: "/dev/null")
        }
        
        mutating func resolveBookmark() {
            var isStale = false
            do {
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: [.withSecurityScope],
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                self.resolvedURL = url
                self.isStale = isStale
                
                if url.startAccessingSecurityScopedResource() {
                    // Access started
                }
            } catch {
                self.resolvedURL = nil
                self.isStale = true
            }
        }
    }
    
    // Codable wrapper for persistence
    private struct PersistedFile: Codable {
        let id: UUID
        let bookmarkData: Data
        let displayName: String
        let fileExtension: String
        let savedAt: Date
        var isPinned: Bool
        
        init(from file: VaultFile) {
            self.id = file.id
            self.bookmarkData = file.bookmarkData
            self.displayName = file.displayName
            self.fileExtension = file.fileExtension
            self.savedAt = file.savedAt
            self.isPinned = file.isPinned
        }
        
        func toVaultFile() -> VaultFile {
            VaultFile(
                id: id,
                bookmarkData: bookmarkData,
                displayName: displayName,
                fileExtension: fileExtension,
                savedAt: savedAt,
                isPinned: isPinned
            )
        }
    }
    
    // MARK: - Init
    
    init() {
        /* ☢️ NUCLEAR RESET DISABLED - Persistence is now active
        // This code would wipe ALL app data. Commented out for production.
        if let bundleID = Bundle.main.bundleIdentifier {
            // 强制清除所有数据
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            // 额外清除：强制清除具体的文件存储 Key，双重保险
            UserDefaults.standard.removeObject(forKey: "file_vault_bookmarks_v2")
            UserDefaults.standard.synchronize()
            
            print("☢️ NUCLEAR RESET: 数据已彻底清除！")
        }
        */
        
        loadFromDisk()
        pruneExpiredFiles()  // Auto-cleanup: remove files older than 3 days
        loadCollapsedSections()
        resolveAllBookmarks()
    }
    
    deinit {
        for file in files {
            file.resolvedURL?.stopAccessingSecurityScopedResource()
        }
    }
    
    // MARK: - Public API
    
    @discardableResult
    func addFile(url: URL) -> Bool {
        let normalizedPath = url.standardizedFileURL.path
        
        if let existingIndex = files.firstIndex(where: { $0.resolvedURL?.standardizedFileURL.path == normalizedPath }) {
            let updated = files[existingIndex]
            files.remove(at: existingIndex)
            let newFile = VaultFile(url: url, isPinned: updated.isPinned)
            files.insert(newFile, at: pinnedCount)
            saveToDisk()
            return false
        }
        
        let newFile = VaultFile(url: url)
        files.insert(newFile, at: pinnedCount)
        
        while files.count > Self.maxStoredFiles {
            if let removeIndex = files.lastIndex(where: { !$0.isPinned }) {
                let removed = files.remove(at: removeIndex)
                removed.resolvedURL?.stopAccessingSecurityScopedResource()
            } else {
                break
            }
        }
        
        saveToDisk()
        return true
    }
    
    @discardableResult
    func addFiles(urls: [URL]) -> Int {
        var addedCount = 0
        for url in urls {
            if addFile(url: url) {
                addedCount += 1
            }
        }
        lastAddedCount = urls.count
        return addedCount
    }
    
    // MARK: - Operation Zombie Killer: Strict Deletion Logic
    func removeFile(id: UUID) {
        guard let index = files.firstIndex(where: { $0.id == id }) else { return }
        
        // 1. CAPTURE reference before removal
        let fileToRemove = files[index]
        
        // 2. UI UPDATE FIRST (Optimistic & Ruthless)
        // We remove it from the array immediately. The UI updates instantly.
        files.remove(at: index)
        
        // 3. Clear selection if needed
        if selectedFileID == id {
            selectedFileID = nil
        }
        
        // 4. PERSISTENCE (Immediate)
        // We save the NEW state (without the file) to disk immediately.
        // This ensures that even if the app crashes right now, the file is gone.
        saveToDisk()
        
        #if DEBUG
        print("✅ UI State Updated: Removed \(fileToRemove.displayName)")
        #endif
        
        // 5. BACKGROUND CLEANUP (Best Effort)
        // We attempt to delete the physical file. If it fails (e.g. file missing),
        // we DO NOT care, because the user's intent was "Get this out of my list".
        DispatchQueue.global(qos: .background).async {
            // First, stop accessing the security scope
            fileToRemove.resolvedURL?.stopAccessingSecurityScopedResource()
            
            // Try to delete physical file
            if let url = fileToRemove.resolvedURL {
                do {
                    try FileManager.default.removeItem(at: url)
                    print("🗑️ Disk File Deleted: \(url.lastPathComponent)")
                } catch {
                    // This is EXPECTED if the file was already "Missing"
                    print("⚠️ Disk Delete Skipped/Failed: \(error.localizedDescription) (This is okay, item is already gone from UI)")
                }
            }
        }
    }
    
    func togglePin(id: UUID) {
        guard let index = files.firstIndex(where: { $0.id == id }) else { return }
        files[index].isPinned.toggle()
        
        files.sort { file1, file2 in
            if file1.isPinned != file2.isPinned {
                return file1.isPinned
            }
            return file1.savedAt > file2.savedAt
        }
        
        saveToDisk()
    }
    
    func clearUnpinned() {
        let toRemove = files.filter { !$0.isPinned }
        for file in toRemove {
            file.resolvedURL?.stopAccessingSecurityScopedResource()
        }
        files.removeAll { !$0.isPinned }
        selectedFileID = nil
        saveToDisk()
    }
    
    func clearAll() {
        for file in files {
            file.resolvedURL?.stopAccessingSecurityScopedResource()
        }
        files.removeAll()
        selectedFileID = nil
        saveToDisk()
    }
    
    func openFile(id: UUID) -> Bool {
        guard let file = files.first(where: { $0.id == id }),
              let url = file.resolvedURL,
              file.fileExists else {
            return false
        }
        return NSWorkspace.shared.open(url)
    }
    
    func revealInFinder(id: UUID) {
        guard let file = files.first(where: { $0.id == id }),
              let url = file.resolvedURL,
              file.fileExists else {
            return
        }
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }
    
    func copyPath(id: UUID) {
        guard let file = files.first(where: { $0.id == id }) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(file.path, forType: .string)
    }
    
    // MARK: - Keyboard Navigation
    
    func selectNext() {
        let sortedFiles = self.sortedFiles
        guard !sortedFiles.isEmpty else { return }
        
        if let currentID = selectedFileID,
           let currentIndex = sortedFiles.firstIndex(where: { $0.id == currentID }) {
            let nextIndex = min(currentIndex + 1, sortedFiles.count - 1)
            selectedFileID = sortedFiles[nextIndex].id
        } else {
            selectedFileID = sortedFiles.first?.id
        }
    }
    
    func selectPrevious() {
        let sortedFiles = self.sortedFiles
        guard !sortedFiles.isEmpty else { return }
        
        if let currentID = selectedFileID,
           let currentIndex = sortedFiles.firstIndex(where: { $0.id == currentID }) {
            let previousIndex = max(currentIndex - 1, 0)
            selectedFileID = sortedFiles[previousIndex].id
        } else {
            selectedFileID = sortedFiles.last?.id
        }
    }
    
    func openSelected() -> Bool {
        guard let id = selectedFileID else { return false }
        return openFile(id: id)
    }
    
    func removeSelected() {
        guard let id = selectedFileID else { return }
        removeFile(id: id)
    }
    
    // MARK: - Computed
    
    var sortedFiles: [VaultFile] {
        files.sorted { file1, file2 in
            if file1.isPinned != file2.isPinned {
                return file1.isPinned
            }
            return file1.savedAt > file2.savedAt
        }
    }
    
    var groupedFiles: [(kind: FileKind, files: [VaultFile])] {
        var groups: [FileKind: [VaultFile]] = [:]
        for file in sortedFiles {
            groups[file.fileKind, default: []].append(file)
        }
        
        return FileKind.allCases
            .compactMap { kind -> (kind: FileKind, files: [VaultFile])? in
                guard let files = groups[kind], !files.isEmpty else { return nil }
                return (kind: kind, files: files)
            }
    }
    
    var isEmpty: Bool { files.isEmpty }
    var fileCount: Int { files.count }
    var pinnedCount: Int { files.filter { $0.isPinned }.count }
    var unpinnedCount: Int { files.count - pinnedCount }
    
    // MARK: - Section Collapse
    
    func toggleSectionCollapsed(_ kind: FileKind) {
        if collapsedSections.contains(kind) {
            collapsedSections.remove(kind)
        } else {
            collapsedSections.insert(kind)
        }
        saveCollapsedSections()
    }
    
    func isSectionCollapsed(_ kind: FileKind) -> Bool {
        collapsedSections.contains(kind)
    }
    
    private func loadCollapsedSections() {
        guard let data = UserDefaults.standard.data(forKey: collapsedSectionsKey),
              let rawValues = try? JSONDecoder().decode([String].self, from: data) else {
            return
        }
        collapsedSections = Set(rawValues.compactMap { FileKind(rawValue: $0) })
    }
    
    private func saveCollapsedSections() {
        let rawValues = collapsedSections.map { $0.rawValue }
        if let data = try? JSONEncoder().encode(rawValues) {
            UserDefaults.standard.set(data, forKey: collapsedSectionsKey)
        }
    }
    
    // MARK: - Persistence
    
    private func saveToDisk() {
        let persistedFiles = files.map { PersistedFile(from: $0) }
        if let encoded = try? JSONEncoder().encode(persistedFiles) {
            UserDefaults.standard.set(encoded, forKey: persistenceKey)
        }
    }
    
    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let decoded = try? JSONDecoder().decode([PersistedFile].self, from: data) else {
            return
        }
        files = decoded.map { $0.toVaultFile() }
    }
    
    private func resolveAllBookmarks() {
        for i in files.indices {
            files[i].resolveBookmark()
        }
    }
    
    // MARK: - Auto-Pruning (3-Day Retention)
    
    /// Remove files older than 3 days (72 hours) to prevent indefinite accumulation.
    /// Respects pinned files - they are never auto-pruned.
    private func pruneExpiredFiles() {
        let now = Date()
        let retentionWindow: TimeInterval = 72 * 60 * 60  // 3 days in seconds
        
        // Find expired unpinned files
        let expiredFiles = files.filter { file in
            !file.isPinned && now.timeIntervalSince(file.savedAt) > retentionWindow
        }
        
        guard !expiredFiles.isEmpty else {
            #if DEBUG
            logger.debug("🧹 Auto-prune: No expired files found")
            #endif
            return
        }
        
        #if DEBUG
        logger.debug("🧹 Auto-pruning \(expiredFiles.count) expired file(s) (older than 3 days)")
        #endif
        
        // Remove expired files from array
        let idsToRemove = Set(expiredFiles.map { $0.id })
        files.removeAll { idsToRemove.contains($0.id) }
        
        // Save updated state to disk
        saveToDisk()
        
        // Background cleanup: release security-scoped resources and attempt physical deletion
        DispatchQueue.global(qos: .background).async {
            for file in expiredFiles {
                // Release security-scoped resource
                file.resolvedURL?.stopAccessingSecurityScopedResource()
                
                // Attempt to delete physical file (best effort, ignore errors)
                if let url = file.resolvedURL {
                    do {
                        try FileManager.default.removeItem(at: url)
                        #if DEBUG
                        print("🧹 Auto-pruned disk file: \(url.lastPathComponent)")
                        #endif
                    } catch {
                        // Silently ignore - file may already be missing or moved
                        #if DEBUG
                        print("🧹 Disk delete skipped for: \(file.displayName) (\(error.localizedDescription))")
                        #endif
                    }
                }
            }
        }
    }
}
