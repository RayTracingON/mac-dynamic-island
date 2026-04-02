import Foundation
import SwiftUI
import Combine

/// Main music player manager (wrapper for MusicManager)
@MainActor
class MusicPlayerManager: ObservableObject {
    static let shared = MusicPlayerManager()
    
    private let musicManager = MusicManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Forwarded published properties
    @Published var isPlaying: Bool = false
    @Published var currentTrack: MusicTrack?
    @Published var albumArt: NSImage = NSImage(systemSymbolName: "music.note", accessibilityDescription: nil)!
    @Published var volume: Float = 0.5
    @Published var isShuffled: Bool = false
    @Published var repeatMode: MusicRepeatMode = .off
    @Published var currentTime: Double = 0
    @Published var needsAccessibilityPermission: Bool = false
    
    private init() {
        setupBindings()
    }
    
    private func setupBindings() {
        musicManager.$isPlaying
            .assign(to: &$isPlaying)
        
        musicManager.$volume
            .map { Float($0) }
            .assign(to: &$volume)
        
        musicManager.$isShuffled
            .assign(to: &$isShuffled)
        
        musicManager.$repeatMode
            .assign(to: &$repeatMode)
        
        musicManager.$albumArt
            .assign(to: &$albumArt)
            
        musicManager.$currentDisplayTime
            .assign(to: &$currentTime)
            
        musicManager.$needsAccessibilityPermission
            .assign(to: &$needsAccessibilityPermission)
        
        // Create track from music manager properties
        Publishers.CombineLatest4(
            musicManager.$songTitle,
            musicManager.$artistName,
            musicManager.$albumTitle,
            musicManager.$songDuration
        )
        .map { title, artist, album, duration in
            guard !title.isEmpty || !artist.isEmpty else { return nil }
            return MusicTrack(
                title: title,
                artist: artist,
                album: album,
                duration: duration,
                albumArtURL: nil
            )
        }
        .assign(to: &$currentTrack)
    }
    
    // MARK: - Lifecycle
    
    func start() {
        musicManager.start()
    }
    
    func stop() {
        musicManager.stop()
    }
    
    // MARK: - Playback Control
    
    func play() {
        musicManager.play()
    }
    
    func pause() {
        musicManager.pause()
    }
    
    func togglePlayPause() {
        musicManager.togglePlay()
    }
    
    func next() {
        musicManager.nextTrack()
    }
    
    func previous() {
        musicManager.previousTrack()
    }
    
    func seek(to position: TimeInterval) {
        musicManager.seek(to: position)
    }
    
    // MARK: - Volume Control
    
    func setVolume(_ value: Float) {
        musicManager.setVolume(to: Double(value))
    }
    
    func increaseVolume() {
        let newVolume = min(volume + 0.1, 1.0)
        setVolume(newVolume)
    }
    
    func decreaseVolume() {
        let newVolume = max(volume - 0.1, 0.0)
        setVolume(newVolume)
    }
    
    // MARK: - Shuffle & Repeat
    
    func toggleShuffle() {
        musicManager.toggleShuffle()
    }
    
    func cycleRepeatMode() {
        musicManager.toggleRepeat()
    }
    
    // MARK: - App Control
    
    func openMusicApp() {
        musicManager.openMusicApp()
    }
    
    func forceUpdate() {
        musicManager.forceUpdate()
    }
}
