import Foundation
import Combine

#if APP_STORE
/// Stub implementation for App Store builds
class KeyboardBacklightManager: ObservableObject {
    static let shared = KeyboardBacklightManager()
    
    @Published var brightness: Double = 0.0
    @Published var isAvailable: Bool = false
    
    private init() {}
    
    func setBrightness(_ value: Double) {}
    func updateBrightness() {}
    func increaseBrightness(by delta: Double = 0.1) {}
    func decreaseBrightness(by delta: Double = 0.1) {}
    func turnOff() {}
    func turnOn() {}
    func toggle() {}
    var isOn: Bool { false }
    var brightnessPercentage: Int { 0 }
}
#else
import IOKit

/// Manager for keyboard backlight control
/// Note: IOKit direct hardware access is not allowed in sandboxed App Store apps
class KeyboardBacklightManager: ObservableObject {
    static let shared = KeyboardBacklightManager()
    
    @Published var brightness: Double = 0.0
    @Published var isAvailable: Bool = false
    
    private var service: io_service_t = 0
    private var connect: io_connect_t = 0
    
    private init() {
        setupIOService()
        updateBrightness()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Setup
    
    private func setupIOService() {
        if #available(macOS 12.0, *) {
            service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleLMUController"))
        } else {
            service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleLMUController"))
        } // Handle potential OS version compatibility
        
        guard service != 0 else {
            isAvailable = false
            return
        }
        
        let result = IOServiceOpen(service, mach_task_self_, 0, &connect)
        isAvailable = (result == kIOReturnSuccess)
    }
    
    private func cleanup() {
        if connect != 0 {
            IOServiceClose(connect)
            connect = 0
        }
        
        if service != 0 {
            IOObjectRelease(service)
            service = 0
        }
    }
    
    // MARK: - Brightness Control
    
    func setBrightness(_ value: Double) {
        guard isAvailable, connect != 0 else { return }
        
        let clampedValue = max(0.0, min(1.0, value))
        let scaledValue = UInt32(clampedValue * 0x1000) // Scale to 0-4096
        
        var inputValues: [UInt64] = [UInt64(scaledValue)]
        let inputCount = UInt32(inputValues.count)
        
        let result = IOConnectCallScalarMethod(
            connect,
            1, // Method selector for set brightness
            &inputValues,
            inputCount,
            nil,
            nil
        )
        
        if result == kIOReturnSuccess {
            DispatchQueue.main.async { [weak self] in
                self?.brightness = clampedValue
            }
        }
    }
    
    func updateBrightness() {
        guard isAvailable, connect != 0 else { return }
        
        var outputValues: [UInt64] = [0]
        var outputCount = UInt32(outputValues.count)
        
        let result = IOConnectCallScalarMethod(
            connect,
            0, // Method selector for get brightness
            nil,
            0,
            &outputValues,
            &outputCount
        )
        
        if result == kIOReturnSuccess {
            let scaledValue = Double(outputValues[0]) / 0x1000
            DispatchQueue.main.async { [weak self] in
                self?.brightness = scaledValue
            }
        }
    }
    
    // MARK: - Convenience
    
    func increaseBrightness(by delta: Double = 0.1) {
        setBrightness(brightness + delta)
    }
    
    func decreaseBrightness(by delta: Double = 0.1) {
        setBrightness(brightness - delta)
    }
    
    func turnOff() {
        setBrightness(0.0)
    }
    
    func turnOn() {
        setBrightness(1.0)
    }
    
    func toggle() {
        if brightness > 0 {
            turnOff()
        } else {
            turnOn()
        }
    }
    
    // MARK: - Info
    
    var isOn: Bool {
        return brightness > 0
    }
    
    var brightnessPercentage: Int {
        return Int(brightness * 100)
    }
}
#endif
