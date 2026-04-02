//
//  AppleMusicController.swift
//  boringNotch
//
//  Created by Alexander on 2025-08-22.
//

import Foundation
import AppKit
import Combine

#if APP_STORE
/// Stub implementation for App Store builds
class AppleMusicController: MediaControllerProtocol {
    var isRunning: Bool { false }
    var supportsPlaybackControl: Bool { false }
    var supportsSeek: Bool { false }
    var supportsRepeat: Bool { false }
    var supportsShuffle: Bool { false }
    var supportsFavorite: Bool { false }
    var supportsVolume: Bool { false }
    let bundleIdentifier = "com.apple.Music"
    
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
    func toggleFavorite() {}
    func setVolume(_ volume: Double) {}
    func getVolume() async -> Double { 0.5 }
    func getCurrentState() async -> PlaybackState { PlaybackState() }
    func openMusicApp() {}
}
#else
/// Apple Music controller using AppleScript
/// Note: AppleScript automation is not allowed in sandboxed App Store apps
class AppleMusicController: MediaControllerProtocol {
    var isRunning: Bool {
        return NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleIdentifier }
    }
    
    var supportsPlaybackControl: Bool { true }
    var supportsSeek: Bool { true }
    var supportsRepeat: Bool { true }
    var supportsShuffle: Bool { true }
    var supportsFavorite: Bool { true }
    var supportsVolume: Bool { true }
    
    let bundleIdentifier = "com.apple.Music"
    
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
        tell application "Music"
            play
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func pause() {
        let script = """
        tell application "Music"
            pause
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func togglePlayPause() {
        let script = """
        tell application "Music"
            playpause
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func nextTrack() {
        let script = """
        tell application "Music"
            next track
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func previousTrack() {
        let script = """
        tell application "Music"
            previous track
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func seek(to position: TimeInterval) {
        let script = """
        tell application "Music"
            set player position to \(position)
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func toggleShuffle() {
        let script = """
        tell application "Music"
            set shuffle enabled to not shuffle enabled
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func toggleRepeat() {
        let script = """
        tell application "Music"
            if song repeat is off then
                set song repeat to all
            else if song repeat is all then
                set song repeat to one
            else
                set song repeat to off
            end if
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func toggleFavorite() {
        let script = """
        tell application "Music"
            set loved of current track to not loved of current track
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func setVolume(_ volume: Double) {
        let volumePercent = Int(volume * 100)
        let script = """
        tell application "Music"
            set sound volume to \(volumePercent)
        end tell
        """
        AppleScriptHelper.executeScriptVoid(script)
    }
    
    func getVolume() async -> Double {
        let script = """
        tell application "Music"
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
        tell application "Music"
            set output to ""
            try
                set currentTrack to current track
                set output to output & name of currentTrack & "|"
                set output to output & artist of currentTrack & "|"
                set output to output & album of currentTrack & "|"
                
                if player state is playing then
                    set output to output & "playing|"
                else
                    set output to output & "paused|"
                end if
                
                set output to output & player position & "|"
                set output to output & duration of currentTrack & "|"
                set output to output & player position & "|"
                
                if shuffle enabled then
                    set output to output & "true|"
                else
                    set output to output & "false|"
                end if
                
                if song repeat is off then
                    set output to output & "off|"
                else if song repeat is all then
                    set output to output & "all|"
                else
                    set output to output & "one|"
                end if
                
                if loved of currentTrack then
                    set output to output & "true|"
                else
                    set output to output & "false|"
                end if
                
                set output to output & sound volume
                
                return output
            end try
            return ""
        end tell
        """
        
        guard let result = AppleScriptHelper.executeScript(script), !result.isEmpty else {
            return PlaybackState()
        }
        
        let components = result.split(separator: "|").map(String.init)
        guard components.count >= 10 else {
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
        
        switch components[8] {
        case "off": state.repeatMode = .off
        case "all": state.repeatMode = .all
        case "one": state.repeatMode = .one
        default: state.repeatMode = .off
        }
        
        state.isFavorite = components[9] == "true"
        
        if components.count > 10, let volumeInt = Int(components[10]) {
            state.volume = Double(volumeInt) / 100.0
        }
        
        state.bundleIdentifier = bundleIdentifier
        state.applicationName = "Music"
        state.timestampDate = Date()
        
        // Get artwork
        if let artworkData = getArtworkData(), let image = NSImage(data: artworkData) {
            state.albumArt = image
        }
        
        return state
    }
    
    func openMusicApp() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
        }
    }
    
    private func getArtworkData() -> Data? {
        let script = """
        tell application "Music"
            try
                set currentTrack to current track
                set artworkData to data of artwork 1 of currentTrack
                return artworkData
            end try
        end tell
        """
        
        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: script) else { return nil }
        let output = scriptObject.executeAndReturnError(&error)
        
        if error != nil {
            return nil
        }
        
        return output.data
    }
}
#endif
