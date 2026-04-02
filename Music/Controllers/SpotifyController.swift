//
//  SpotifyController.swift
//  boringNotch
//
//  Created by Alexander on 2025-08-22.
//

import Foundation
import AppKit
import Combine

#if APP_STORE
/// Stub implementation for App Store builds
class SpotifyController: MediaControllerProtocol {
    var isRunning: Bool { false }
    var supportsPlaybackControl: Bool { false }
    var supportsSeek: Bool { false }
    var supportsRepeat: Bool { false }
    var supportsShuffle: Bool { false }
    var supportsFavorite: Bool { false }
    var supportsVolume: Bool { false }
    let bundleIdentifier = "com.spotify.client"
    
    func start(onChange: @escaping (PlaybackState) -> Void) {}
    func stop() {}
    func play() {}
    func pause() {}
    func togglePlayPause() {}
    func nextTrack() {}
    func previousTrack() {}
    func seek(to position: TimeInterval) {}
    func toggleShuffle() {}
    func toggleRepeat() {}
    func setVolume(_ volume: Double) {}
    func getVolume() async -> Double { 0.5 }
    func getCurrentState() async -> PlaybackState { PlaybackState() }
    func openMusicApp() {}
}
#else
/// Spotify controller using AppleScript
/// Note: AppleScript automation is not allowed in sandboxed App Store apps
class SpotifyController: MediaControllerProtocol {
    var isRunning: Bool {
        return NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleIdentifier }
    }
    
    var supportsPlaybackControl: Bool { true }
    var supportsSeek: Bool { true }
    var supportsRepeat: Bool { true }
    var supportsShuffle: Bool { true }
    var supportsFavorite: Bool { false }
    var supportsVolume: Bool { true }
    
    let bundleIdentifier = "com.spotify.client"
    
    private var updateTimer: Timer?
    private var onChange: ((PlaybackState) -> Void)?
    
    func start(onChange: @escaping (PlaybackState) -> Void) {
        self.onChange = onChange
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.isRunning else { return }
            
            Task {
                let state = await self.getCurrentState()
                DispatchQueue.main.async {
                    onChange(state)
                }
            }
        }
    }
    
    func stop() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    func play() {
        let script = """
        tell application "Spotify"
            play
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func pause() {
        let script = """
        tell application "Spotify"
            pause
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func togglePlayPause() {
        let script = """
        tell application "Spotify"
            playpause
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func nextTrack() {
        let script = """
        tell application "Spotify"
            next track
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func previousTrack() {
        let script = """
        tell application "Spotify"
            previous track
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func seek(to position: TimeInterval) {
        let positionMs = Int(position * 1000)
        let script = """
        tell application "Spotify"
            set player position to \(positionMs)
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func toggleShuffle() {
        let script = """
        tell application "Spotify"
            set shuffling to not shuffling
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func toggleRepeat() {
        let script = """
        tell application "Spotify"
            if repeating then
                set repeating to false
            else
                set repeating to true
            end if
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func setVolume(_ volume: Double) {
        let volumePercent = Int(volume * 100)
        let script = """
        tell application "Spotify"
            set sound volume to \(volumePercent)
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func getVolume() async -> Double {
        let script = """
        tell application "Spotify"
            return sound volume
        end tell
        """
        if let volumeString = AppleScriptHelper.executeScript(script),
           let volumeInt = Int(volumeString) {
            return Double(volumeInt) / 100.0
        }
        return 0.5
    }
    
    func getCurrentState() async -> PlaybackState {
        let script = """
        tell application "Spotify"
            set output to ""
            try
                set output to output & name of current track & "|"
                set output to output & artist of current track & "|"
                set output to output & album of current track & "|"
                
                if player state is playing then
                    set output to output & "playing|"
                else
                    set output to output & "paused|"
                end if
                
                set output to output & (player position / 1000) & "|"
                set output to output & (duration of current track / 1000) & "|"
                set output to output & (player position / 1000) & "|"
                
                if shuffling then
                    set output to output & "true|"
                else
                    set output to output & "false|"
                end if
                
                if repeating then
                    set output to output & "all|"
                else
                    set output to output & "off|"
                end if
                
                set output to output & sound volume & "|"
                set output to output & artwork url of current track
                
                return output
            end try
            return ""
        end tell
        """
        
        guard let result = AppleScriptHelper.executeScript(script), !result.isEmpty else {
            return PlaybackState()
        }
        
        let components = result.split(separator: "|").map(String.init)
        guard components.count >= 9 else {
            return PlaybackState()
        }
        
        var state = PlaybackState()
        state.songTitle = components[0]
        state.artistName = components[1]
        state.albumTitle = components[2]
        state.isPlaying = components[3] == "playing"
        state.elapsedTime = Double(components[4]) ?? 0
        state.duration = Double(components[5]) ?? 0
        state.isShuffled = components[7] == "true"
        state.repeatMode = components[8] == "all" ? .all : .off
        
        if components.count > 9, let volumeInt = Int(components[9]) {
            state.volume = Double(volumeInt) / 100.0
        }
        
        if components.count > 10 {
            let artworkURL = components[10]
            if let url = URL(string: artworkURL), let data = try? Data(contentsOf: url), let image = NSImage(data: data) {
                state.albumArt = image
            }
        }
        
        state.bundleIdentifier = bundleIdentifier
        state.applicationName = "Spotify"
        state.timestampDate = Date()
        
        return state
    }
    
    func openMusicApp() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
        }
    }
}
#endif
