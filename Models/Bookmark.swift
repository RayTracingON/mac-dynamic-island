import Combine
import Foundation

/// Represents a security-scoped bookmark for persistent file access
struct Bookmark: Codable, Identifiable {
    let id: UUID
    let url: URL
    let bookmarkData: Data
    let createdDate: Date
    var lastAccessedDate: Date
    var accessCount: Int
    
    init(url: URL, bookmarkData: Data) {
        self.id = UUID()
        self.url = url
        self.bookmarkData = bookmarkData
        self.createdDate = Date()
        self.lastAccessedDate = Date()
        self.accessCount = 0
    }
    
    /// Create a bookmark from a URL
    static func create(from url: URL) throws -> Bookmark {
        let bookmarkData = try url.bookmarkData(
            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        return Bookmark(url: url, bookmarkData: bookmarkData)
    }
    
    /// Resolve the bookmark to a URL
    func resolve() throws -> URL {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        
        if isStale {
            throw BookmarkError.staleBookmark
        }
        
        return url
    }
    
    /// Update access tracking
    mutating func recordAccess() {
        lastAccessedDate = Date()
        accessCount += 1
    }
}

enum BookmarkError: Error {
    case staleBookmark
    case accessDenied
    case invalidBookmark
    case fileNotFound
}

/// Manager for handling bookmarks
class BookmarkManager {
    static let shared = BookmarkManager()
    
    private let userDefaultsKey = "com.mac.notch.bookmarks"
    private var bookmarks: [UUID: Bookmark] = [:]
    
    private init() {
        loadBookmarks()
    }
    
    func save(bookmark: Bookmark) {
        bookmarks[bookmark.id] = bookmark
        saveBookmarks()
    }
    
    func remove(bookmarkID: UUID) {
        bookmarks.removeValue(forKey: bookmarkID)
        saveBookmarks()
    }
    
    func get(bookmarkID: UUID) -> Bookmark? {
        return bookmarks[bookmarkID]
    }
    
    func getAllBookmarks() -> [Bookmark] {
        return Array(bookmarks.values)
    }
    
    private func loadBookmarks() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([UUID: Bookmark].self, from: data) else {
            return
        }
        bookmarks = decoded
    }
    
    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    func cleanStaleBookmarks() {
        let staleBookmarks = bookmarks.filter { _, bookmark in
            do {
                _ = try bookmark.resolve()
                return false
            } catch {
                return true
            }
        }
        
        for (id, _) in staleBookmarks {
            bookmarks.removeValue(forKey: id)
        }
        
        if !staleBookmarks.isEmpty {
            saveBookmarks()
        }
    }
}
