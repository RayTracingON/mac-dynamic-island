//
//  BrightnessManager.swift
//  boringNotch
//
//  Created by Alexander on 2025-08-15.
//

import Foundation
import Combine

#if APP_STORE
/// Stub implementation for App Store builds (brightness control not available in sandbox)
class BrightnessManager: ObservableObject {
    static let shared = BrightnessManager()
    
    @Published var currentBrightness: Float = 0.5
    
    private init() {}
    
    func updateBrightness() {}
    func setBrightness(_ brightness: Float) {}
    func setAbsolute(value: Float32) {}
    func increaseBrightness(by amount: Float = 0.05) {}
    func decreaseBrightness(by amount: Float = 0.05) {}
}
#else
import CoreGraphics
import IOKit.graphics

/// Manager for display brightness control using IOKit
/// Note: IOKit display access is not allowed in sandboxed App Store apps
class BrightnessManager: ObservableObject {
    static let shared = BrightnessManager()
    
    @Published var currentBrightness: Float = 0.5
    
    private init() {
        updateBrightness()
    }
    
    func updateBrightness() {
        if let brightness = getBrightness() {
            DispatchQueue.main.async {
                self.currentBrightness = Float(brightness)
            }
        }
    }
    
    private func getBrightness() -> Float? {
        var brightness: Float = 0.5
        var service: io_service_t
        var iterator: io_iterator_t = 0
        
        let matching = IOServiceMatching("IODisplayConnect")
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        
        guard result == kIOReturnSuccess else { return nil }
        
        defer { IOObjectRelease(iterator) }
        
        repeat {
            service = IOIteratorNext(iterator)
            guard service != 0 else { break }
            
            var brightnessValue: Float = 0
            let brightnessResult = IODisplayGetFloatParameter(
                service,
                0,
                kIODisplayBrightnessKey as CFString,
                &brightnessValue
            )
            
            IOObjectRelease(service)
            
            if brightnessResult == kIOReturnSuccess {
                brightness = brightnessValue
                break
            }
        } while true
        
        return brightness
    }
    
    func setBrightness(_ brightness: Float) {
        var service: io_service_t
        var iterator: io_iterator_t = 0
        
        let matching = IOServiceMatching("IODisplayConnect")
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        
        guard result == kIOReturnSuccess else { return }
        
        defer { IOObjectRelease(iterator) }
        
        let clampedBrightness = max(0, min(1, brightness))
        
        repeat {
            service = IOIteratorNext(iterator)
            guard service != 0 else { break }
            
            IODisplaySetFloatParameter(
                service,
                0,
                kIODisplayBrightnessKey as CFString,
                clampedBrightness
            )
            
            IOObjectRelease(service)
        } while true
        
        DispatchQueue.main.async {
            self.currentBrightness = clampedBrightness
        }
    }
    
    func setAbsolute(value: Float32) {
        setBrightness(value)
    }
    
    func increaseBrightness(by amount: Float = 0.05) {
        setBrightness(currentBrightness + amount)
    }
    
    func decreaseBrightness(by amount: Float = 0.05) {
        setBrightness(currentBrightness - amount)
    }
}
#endif
