import Foundation
import AppKit

// MARK: - IslandNowPlayingState (Globally Unique)
struct IslandNowPlayingState: Equatable {
    let isPlaying: Bool
    let playbackRate: Double
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let position: TimeInterval
    let sourceApp: String
    var artworkData: Data?
    
    static let idle = Self(
        isPlaying: false,
        playbackRate: 0,
        title: "",
        artist: "",
        album: "",
        duration: 0,
        position: 0,
        sourceApp: "",
        artworkData: nil
    )
    
    var hasContent: Bool { !title.isEmpty && !sourceApp.isEmpty }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1.0, max(0.0, position / duration))
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.isPlaying == rhs.isPlaying &&
               lhs.playbackRate == rhs.playbackRate &&
               lhs.title == rhs.title &&
               lhs.artist == rhs.artist &&
               lhs.sourceApp == rhs.sourceApp &&
               abs(lhs.position - rhs.position) < 2.0
    }
}
