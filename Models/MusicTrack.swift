import Combine
import Foundation
import AppKit
import OSLog

/// Music track model
struct MusicTrack: Identifiable, Codable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    var currentTime: TimeInterval
    var albumArtURL: URL?
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    var albumArt: NSImage? {
        get async {
            guard let url = albumArtURL else { return nil }
            
            // Try to load from cache
            if let cached = MemoryManager.shared.cachedImage(forKey: url.absoluteString) {
                return cached
            }
            
            // Load from URL
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = NSImage(data: data) {
                    MemoryManager.shared.cacheImage(image, forKey: url.absoluteString)
                    return image
                }
            } catch {
                let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "MusicTrack")
                logger.error("Failed to load album art: \(error.localizedDescription)")
            }
            
            return nil
        }
    }
    
    // Note: LyricLine type defined at module level to avoid forward reference issues
    var lyrics: [LyricLine]? {
        // Placeholder for lyrics
        return nil
    }
    
    init(
        id: String = UUID().uuidString,
        title: String,
        artist: String,
        album: String = "",
        duration: TimeInterval = 0,
        currentTime: TimeInterval = 0,
        albumArtURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.currentTime = currentTime
        self.albumArtURL = albumArtURL
    }
}

/// Lyric line for music tracks
struct LyricLine: Identifiable, Codable {
    let id: UUID
    let timestamp: TimeInterval
    let text: String
    
    init(id: UUID = UUID(), timestamp: TimeInterval, text: String) {
        self.id = id
        self.timestamp = timestamp
        self.text = text
    }
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, text
    }
}

/// Music album model
struct MusicAlbum: Identifiable, Codable {
    let id: String
    let title: String
    let artist: String
    let artworkURL: URL?
    let trackCount: Int
    
    init(
        id: String = UUID().uuidString,
        title: String,
        artist: String,
        artworkURL: URL? = nil,
        trackCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.artworkURL = artworkURL
        self.trackCount = trackCount
    }
}

/// Music artist model
struct MusicArtist: Identifiable, Codable {
    let id: String
    let name: String
    let imageURL: URL?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        imageURL: URL? = nil
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
    }
}
