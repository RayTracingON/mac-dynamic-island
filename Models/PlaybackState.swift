import Combine
//
//  PlaybackState.swift
//  boringNotch
//
//  Created by Alexander on 2025-08-22.
//

import Foundation
import AppKit

struct PlaybackState: Equatable {
    // Canonical fields
    var songTitle: String = ""
    var artistName: String = ""
    var albumTitle: String = ""
    var albumArt: NSImage? = nil
    var isPlaying: Bool = false
    var elapsedTime: Double = 0
    var duration: Double = 0
    var playbackRate: Double = 1.0
    var repeatMode: MusicRepeatMode = .off
    var isShuffled: Bool = false
    var isFavorite: Bool = false
    var volume: Double = 0.5
    var bundleIdentifier: String? = nil
    var applicationName: String? = nil
    
    // Timestamp used to estimate playback position
    var timestampDate: Date = Date()
    
    // Additional interoperability fields expected by some controllers
    var lastUpdateTime: Date? = nil
    
    // Bridging aliases for compatibility with various controllers
    var title: String {
        get { songTitle }
        set { songTitle = newValue }
    }
    var artist: String {
        get { artistName }
        set { artistName = newValue }
    }
    var album: String {
        get { albumTitle }
        set { albumTitle = newValue }
    }
    var position: Double {
        get { elapsedTime }
        set { elapsedTime = newValue }
    }
    var appName: String {
        get { applicationName ?? "" }
        set { applicationName = newValue }
    }
    
    static var empty: PlaybackState { PlaybackState() }
    
    var isPlayerIdle: Bool {
        return songTitle.isEmpty && artistName.isEmpty
    }
}
