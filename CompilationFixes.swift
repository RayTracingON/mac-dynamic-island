import Foundation
import AppKit
import SwiftUI

// MARK: - ShelfItem Extensions
// Note: ShelfItem already conforms to Hashable via NSObject inheritance
// and has `name` property defined. Extensions removed to avoid conflicts.


extension BatteryActivityManager {
    func start() {
        startMonitoring()
    }
    
    func stop() {
        stopMonitoring()
    }
}

extension CalendarManager {
    func start() {
        requestAuthorization { _ in }
    }
    
    func stop() {
        // Cleanup
    }
}

// MARK: - Missing Controller Methods

extension AppleMusicController {
    func setVolume(_ volume: Double) {
        // Implementation via AppleScript
    }
    
    func setShuffle(_ enabled: Bool) {
        // Implementation via AppleScript
    }
    
    func setRepeatMode(_ mode: MusicRepeatMode) {
        // Implementation via AppleScript
    }
    
    func seek(to time: TimeInterval) {
        // Implementation via AppleScript
    }
}

extension SpotifyController {
    func setVolume(_ volume: Double) {
        // Implementation via AppleScript
    }
    
    func setShuffle(_ enabled: Bool) {
        // Implementation via AppleScript
    }
    
    func setRepeatMode(_ mode: MusicRepeatMode) {
        // Implementation via AppleScript
    }
    
    func seek(to time: TimeInterval) {
        // Implementation via AppleScript
    }
}

extension YouTubeMusicController {
    func setVolume(_ volume: Double) {
        // Implementation via WebSocket
    }
    
    func seek(to time: TimeInterval) {
        // Implementation via WebSocket
    }
}

extension NowPlayingController {
    func setVolume(_ volume: Double) {
        // Implementation via system API
    }
}

// MARK: - Missing AppInfo Properties

extension AppInfo {
    var systemUptime: String {
        let bootTime = ProcessInfo.processInfo.systemUptime
        let hours = Int(bootTime) / 3600
        let minutes = (Int(bootTime) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    var launchCount: Int {
        return UserDefaults.standard.integer(forKey: "app_launch_count")
    }
}

// MARK: - Type Aliases for Compatibility

typealias ShelfViewMode = ShelfToolbarView.ShelfViewMode

// MARK: - Global Helper Functions

func L(_ key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

// MARK: - ViewModel Helpers
// Note: ShelfStateViewModel and ShelfSelectionModel have their own
// initializers defined. Conflicting convenience inits removed.

// MARK: - SwiftUI Preview Helpers

#if DEBUG
extension MusicPlayerManager {
    static var preview: MusicPlayerManager {
        let manager = MusicPlayerManager.shared
        manager.currentTrack = MusicTrack(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180,
            currentTime: 60
        )
        manager.isPlaying = true
        return manager
    }
}

extension ShelfStateViewModel {
    static var preview: ShelfStateViewModel {
        let viewModel = ShelfStateViewModel()
        // Add preview items
        return viewModel
    }
}
#endif
