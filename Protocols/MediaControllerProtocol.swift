//
//  MediaControllerProtocol.swift
//  boringNotch
//
//  Created by Alexander on 2025-08-20.
//

import Foundation
import AppKit

protocol MediaControllerProtocol: AnyObject {
    var isRunning: Bool { get }
    var supportsPlaybackControl: Bool { get }
    var supportsSeek: Bool { get }
    var supportsRepeat: Bool { get }
    var supportsShuffle: Bool { get }
    var supportsFavorite: Bool { get }
    var supportsVolume: Bool { get }
    var bundleIdentifier: String { get }
    
    func start(onChange: @escaping (PlaybackState) -> Void)
    func stop()
    
    func play()
    func pause()
    func togglePlayPause()
    func nextTrack()
    func previousTrack()
    func seek(to position: TimeInterval)
    func skip(seconds: TimeInterval)
    
    func toggleShuffle()
    func toggleRepeat()
    func toggleFavorite()
    
    func setVolume(_ volume: Double)
    func getVolume() async -> Double
    
    func getCurrentState() async -> PlaybackState
    func openMusicApp()
}

// Default implementations
extension MediaControllerProtocol {
    var supportsPlaybackControl: Bool { true }
    var supportsSeek: Bool { true }
    var supportsRepeat: Bool { false }
    var supportsShuffle: Bool { false }
    var supportsFavorite: Bool { false }
    var supportsVolume: Bool { false }
    
    func toggleShuffle() {}
    func toggleRepeat() {}
    func toggleFavorite() {}
    func setVolume(_ volume: Double) {}
    func getVolume() async -> Double { return 0.5 }
    func skip(seconds: TimeInterval) {
        Task {
            let state = await getCurrentState()
            let newPosition = state.elapsedTime + seconds
            let clampedPosition = max(0, min(newPosition, state.duration))
            seek(to: clampedPosition)
        }
    }
}
