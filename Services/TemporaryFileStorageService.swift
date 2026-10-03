import Foundation

/// Text dropped on the shelf is kept here as a file, so it can be dragged out again
class TemporaryFileStorageService {
    static let shared = TemporaryFileStorageService()

    private let tempDirectory: URL

    private init() {
        // Create app-specific temp directory
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Mac灵动岛", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    /// Create temporary file with content
    func createTemporary(content: String, filename: String) throws -> URL {
        let fileURL = tempDirectory.appendingPathComponent(filename)
        try Data(content.utf8).write(to: fileURL)
        return fileURL
    }
}
