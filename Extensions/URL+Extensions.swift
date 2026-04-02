import Foundation
import AppKit

extension URL {
    /// Get file icon
    var fileIcon: NSImage? {
        return NSWorkspace.shared.icon(forFile: path)
    }
    
    /// Get file size
    var fileSize: Int64 {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attributes[.size] as? Int64 else {
            return 0
        }
        return size
    }
    
    /// Check if URL is a directory
    var isDirectory: Bool {
        guard let values = try? resourceValues(forKeys: [.isDirectoryKey]) else {
            return false
        }
        return values.isDirectory ?? false
    }
    
    /// Get file creation date
    var creationDate: Date? {
        guard let values = try? resourceValues(forKeys: [.creationDateKey]) else {
            return nil
        }
        return values.creationDate
    }
    
    /// Get file modification date
    var modificationDate: Date? {
        guard let values = try? resourceValues(forKeys: [.contentModificationDateKey]) else {
            return nil
        }
        return values.contentModificationDate
    }
    
    /// Get file UTI type
    var contentType: String? {
        guard let values = try? resourceValues(forKeys: [.typeIdentifierKey]) else {
            return nil
        }
        return values.typeIdentifier
    }
    
    /// Open URL in default application
    func open() {
        NSWorkspace.shared.open(self)
    }
    
    /// Reveal in Finder
    func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([self])
    }
    
    /// Check if file exists
    var exists: Bool {
        return FileManager.default.fileExists(atPath: path)
    }
}
