import Combine
import Foundation
import IOKit
import IOKit.ps

/// Comprehensive battery monitoring using IOKit
/// Provides real-time battery status, charging state, health, and power source info
class BatteryActivityManager: ObservableObject {
    static let shared = BatteryActivityManager()
    
    // MARK: - Published Properties
    
    @Published var isCharging: Bool = false
    @Published var isPluggedIn: Bool = false
    @Published var batteryLevel: Int = 0
    @Published var batteryPercentage: Double = 0.0
    @Published var timeRemaining: Int = 0 // Minutes
    @Published var isFullyCharged: Bool = false
    @Published var isLowPowerMode: Bool = false
    @Published var batteryHealth: String = "Unknown"
    @Published var cycleCount: Int = 0
    @Published var temperature: Double = 0.0
    @Published var voltage: Double = 0.0
    @Published var amperage: Int = 0
    @Published var powerSource: String = "Unknown"
    @Published var isCalculatingTime: Bool = false
    
    // MARK: - Private Properties
    
    private var runLoopSource: CFRunLoopSource?
    private var updateTimer: Timer?
    
    private init() {}
    
    deinit {
        stop()
    }
    
    // MARK: - Lifecycle
    
    func start() {
        // Initial update
        updateBatteryStatus()
        
        // Register for power source changes
        registerForPowerSourceChanges()
        
        // Start periodic updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateBatteryStatus()
        }
    }
    
    func stop() {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
            self.runLoopSource = nil
        }
        
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Power Source Monitoring
    
    private func registerForPowerSourceChanges() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        let callback: IOPowerSourceCallbackType = { context in
            guard let context = context else { return }
            let manager = Unmanaged<BatteryActivityManager>.fromOpaque(context).takeUnretainedValue()
            manager.updateBatteryStatus()
        }
        
        runLoopSource = IOPSNotificationCreateRunLoopSource(callback, context).takeRetainedValue()
        
        if let runLoopSource = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
        }
    }
    
    // MARK: - Battery Status Update
    
    func updateBatteryStatus() {
        // Get power source info
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return
        }
        
        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.parseBasicInfo(info)
                self?.parseDetailedInfo()
            }
        }
    }
    
    private func parseBasicInfo(_ info: [String: Any]) {
        // Power source type
        if let type = info[kIOPSTypeKey] as? String {
            powerSource = type
        }
        
        // Charging state
        if let state = info[kIOPSPowerSourceStateKey] as? String {
            isPluggedIn = (state == kIOPSACPowerValue)
        }
        
        if let charging = info[kIOPSIsChargingKey] as? Bool {
            isCharging = charging
        }
        
        // Battery level
        if let current = info[kIOPSCurrentCapacityKey] as? Int,
           let max = info[kIOPSMaxCapacityKey] as? Int,
           max > 0 {
            batteryLevel = current
            batteryPercentage = Double(current) / Double(max) * 100.0
        }
        
        // Fully charged
        if let charged = info[kIOPSIsChargedKey] as? Bool {
            isFullyCharged = charged
        }
        
        // Time remaining
        if let timeToEmpty = info[kIOPSTimeToEmptyKey] as? Int {
            if timeToEmpty == -1 {
                isCalculatingTime = true
                timeRemaining = 0
            } else {
                isCalculatingTime = false
                timeRemaining = timeToEmpty
            }
        } else if let timeToFull = info[kIOPSTimeToFullChargeKey] as? Int {
            if timeToFull == -1 {
                isCalculatingTime = true
                timeRemaining = 0
            } else {
                isCalculatingTime = false
                timeRemaining = timeToFull
            }
        }
        
        // Low power mode (key doesn't exist in IOKit, check via ProcessInfo)
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    private func parseDetailedInfo() {
        // Get battery service
        guard let service = getBatteryService() else { return }
        
        // Cycle count
        if let cycles = getIntProperty(service: service, key: "CycleCount") {
            cycleCount = cycles
        }
        
        // Temperature (in Celsius)
        if let temp = getDoubleProperty(service: service, key: "Temperature") {
            temperature = temp / 100.0 // Convert from centi-Celsius
        }
        
        // Voltage (in mV)
        if let volt = getIntProperty(service: service, key: "Voltage") {
            voltage = Double(volt) / 1000.0 // Convert to Volts
        }
        
        // Amperage (in mA)
        if let amp = getIntProperty(service: service, key: "Amperage") {
            amperage = amp
        }
        
        // Battery health
        if let maxCapacity = getIntProperty(service: service, key: "MaxCapacity"),
           let designCapacity = getIntProperty(service: service, key: "DesignCapacity"),
           designCapacity > 0 {
            let healthPercent = Double(maxCapacity) / Double(designCapacity) * 100.0
            
            if healthPercent >= 95 {
                batteryHealth = "Excellent"
            } else if healthPercent >= 80 {
                batteryHealth = "Good"
            } else if healthPercent >= 60 {
                batteryHealth = "Fair"
            } else {
                batteryHealth = "Poor"
            }
        }
        
        IOObjectRelease(service)
    }
    
    // MARK: - IOKit Helpers
    
    private func getBatteryService() -> io_service_t? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery")
        )
        
        return service != 0 ? service : nil
    }
    
    private func getIntProperty(service: io_service_t, key: String) -> Int? {
        guard let value = IORegistryEntryCreateCFProperty(
            service,
            key as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? Int else {
            return nil
        }
        return value
    }
    
    private func getDoubleProperty(service: io_service_t, key: String) -> Double? {
        guard let value = IORegistryEntryCreateCFProperty(
            service,
            key as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? Double else {
            return nil
        }
        return value
    }
    
    // MARK: - Computed Properties
    
    var batteryStatusText: String {
        if isFullyCharged {
            return "Fully Charged"
        } else if isCharging {
            return "Charging"
        } else if isPluggedIn {
            return "On AC Power"
        } else {
            return "On Battery"
        }
    }
    
    var timeRemainingText: String {
        if isCalculatingTime {
            return "Calculating..."
        }
        
        if isFullyCharged {
            return "Fully charged"
        }
        
        if timeRemaining <= 0 {
            return "Unknown"
        }
        
        let hours = timeRemaining / 60
        let minutes = timeRemaining % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var batteryColor: String {
        if !SettingsDefaults.shared.get(SettingsDefaults.colorizeBatteryLevel) {
            return "primary"
        }
        
        if isCharging {
            return "green"
        }
        
        if batteryPercentage < 20 {
            return "red"
        } else if batteryPercentage < 50 {
            return "orange"
        } else {
            return "green"
        }
    }
    
    var isLowBattery: Bool {
        return batteryPercentage < 20 && !isCharging
    }
    
    var shouldShowNotification: Bool {
        return batteryPercentage <= 10 && !isCharging
    }
    
    // MARK: - Formatted Output
    
    var detailedInfo: String {
        var info = "Battery Status:\n"
        info += "Level: \(Int(batteryPercentage))%\n"
        info += "State: \(batteryStatusText)\n"
        info += "Time: \(timeRemainingText)\n"
        info += "Health: \(batteryHealth)\n"
        info += "Cycles: \(cycleCount)\n"
        info += "Temperature: \(String(format: "%.1f°C", temperature))\n"
        info += "Voltage: \(String(format: "%.2fV", voltage))\n"
        info += "Amperage: \(amperage)mA\n"
        info += "Low Power Mode: \(isLowPowerMode ? "On" : "Off")"
        return info
    }
}
