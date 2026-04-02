//
//  VolumeManager.swift
//  boringNotch
//
//  Created by Alexander on 2025-08-15.
//

import Foundation
import Combine

#if APP_STORE
/// Stub implementation for App Store builds (volume control not available in sandbox)
class VolumeManager: ObservableObject {
    static let shared = VolumeManager()
    
    @Published var currentVolume: Float = 0.5
    @Published var isMuted: Bool = false
    
    private init() {}
    
    func updateVolume() {}
    func setVolume(_ volume: Float) {}
    func setAbsolute(_ volume: Float32) {}
    func increaseVolume(by amount: Float = 0.05) {}
    func decreaseVolume(by amount: Float = 0.05) {}
    func toggleMute() {}
}
#else
import CoreAudio

/// Manager for system volume control using CoreAudio
/// Note: Direct CoreAudio device access may be restricted in sandboxed App Store apps
class VolumeManager: ObservableObject {
    static let shared = VolumeManager()
    
    @Published var currentVolume: Float = 0.5
    @Published var isMuted: Bool = false
    
    private var audioDeviceID: AudioDeviceID = 0
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAudioDevice()
        updateVolume()
    }
    
    private func setupAudioDevice() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var deviceID: AudioDeviceID = 0
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceID
        )
        
        if status == noErr {
            audioDeviceID = deviceID
            registerVolumeChangeListener()
        }
    }
    
    private func registerVolumeChangeListener() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListener(
            audioDeviceID,
            &propertyAddress,
            volumeChangeCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )
    }
    
    func updateVolume() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var volume: Float32 = 0
        var propertySize = UInt32(MemoryLayout<Float32>.size)
        
        let status = AudioObjectGetPropertyData(
            audioDeviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &volume
        )
        
        if status == noErr {
            DispatchQueue.main.async {
                self.currentVolume = volume
            }
        }
    }
    
    func setVolume(_ volume: Float) {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var newVolume = max(0, min(1, volume))
        let propertySize = UInt32(MemoryLayout<Float32>.size)
        
        AudioObjectSetPropertyData(
            audioDeviceID,
            &propertyAddress,
            0,
            nil,
            propertySize,
            &newVolume
        )
        
        DispatchQueue.main.async {
            self.currentVolume = newVolume
        }
    }
    
    func setAbsolute(_ volume: Float32) {
        setVolume(volume)
    }
    
    func increaseVolume(by amount: Float = 0.05) {
        setVolume(currentVolume + amount)
    }
    
    func decreaseVolume(by amount: Float = 0.05) {
        setVolume(currentVolume - amount)
    }
    
    func toggleMute() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var muted: UInt32 = isMuted ? 0 : 1
        let propertySize = UInt32(MemoryLayout<UInt32>.size)
        
        AudioObjectSetPropertyData(
            audioDeviceID,
            &propertyAddress,
            0,
            nil,
            propertySize,
            &muted
        )
        
        DispatchQueue.main.async {
            self.isMuted = (muted == 1)
        }
    }
    
    deinit {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectRemovePropertyListener(
            audioDeviceID,
            &propertyAddress,
            volumeChangeCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )
    }
}

private func volumeChangeCallback(
    _ inObjectID: AudioObjectID,
    _ inNumberAddresses: UInt32,
    _ inAddresses: UnsafePointer<AudioObjectPropertyAddress>,
    _ inClientData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let clientData = inClientData else { return noErr }
    let manager = Unmanaged<VolumeManager>.fromOpaque(clientData).takeUnretainedValue()
    manager.updateVolume()
    return noErr
}
#endif
