import Foundation
import OSLog

/// Modern Logger-based logging system for test readiness.
/// Categories: app, overlay, tray, permissions, services
/// Uses Swift's modern Logger API with proper string interpolation.
struct Log {
    private static let subsystem = "com.maclingdonggao.overlay"
    
    // MARK: - Loggers by Category (Modern Logger API)
    private static let appLogger = os.Logger(subsystem: subsystem, category: "app")
    private static let overlayLogger = os.Logger(subsystem: subsystem, category: "overlay")
    private static let trayLogger = os.Logger(subsystem: subsystem, category: "tray")
    private static let permissionsLogger = os.Logger(subsystem: subsystem, category: "permissions")
    private static let servicesLogger = os.Logger(subsystem: subsystem, category: "services")
    
    // MARK: - App Lifecycle
    static func appDidFinishLaunching() {
        appLogger.info("🚀 App did finish launching")
    }
    
    static func stateChanged(_ property: String, _ oldValue: String, _ newValue: String) {
        appLogger.debug("🔄 State: \(property): \(oldValue) → \(newValue)")
    }
    
    static func activityPosted(_ title: String, _ kind: String) {
        appLogger.info("📌 Activity: posted \(title) (\(kind))")
    }
    
    static func activityDismissed(_ title: String, _ kind: String) {
        appLogger.debug("✕ Activity: dismissed \(title)")
    }
    
    static func timerStarted(_ duration: TimeInterval) {
        appLogger.info("⏱️ Timer: started for \(Int(duration)) seconds")
    }
    
    static func timerStopped() {
        appLogger.info("⏹️ Timer: stopped")
    }
    
    static func appWillTerminate() {
        appLogger.info("🛑 App terminating")
    }
    
    static func appReopenedFromDock() {
        appLogger.info("🔄 App reopened from Dock")
    }
    
    // MARK: - Overlay State Transitions
    static func overlayShowing() {
        overlayLogger.debug("📺 Overlay showing")
    }
    
    static func overlayHiding() {
        overlayLogger.debug("📺 Overlay hiding")
    }
    
    static func overlayExpanded() {
        overlayLogger.debug("📺 Overlay expanded to panel")
    }
    
    static func overlayCompacted() {
        overlayLogger.debug("📺 Overlay compacted to pill")
    }
    
    static func overlayScreenChanged() {
        overlayLogger.debug("📺 Overlay repositioned (screen/space change)")
    }
    
    // MARK: - Input Events
    static func hotkeyTriggered(_ name: String) {
        overlayLogger.debug("⌨️ Hotkey: \(name)")
    }
    
    static func hoverDetected() {
        overlayLogger.debug("🖱️ Hover detected")
    }
    
    static func clickDetected(_ source: String) {
        overlayLogger.debug("🖱️ Click: \(source)")
    }
    
    // MARK: - Tray Actions
    static func trayItemAdded(_ name: String) {
        trayLogger.info("📁 Tray: added \(name)")
    }
    
    static func trayItemRemoved(id: String) {
        trayLogger.info("📁 Tray: removed \(id)")
    }
    
    static func trayCleared() {
        trayLogger.info("📁 Tray: cleared all items")
    }
    
    static func trayItemRevealed(_ name: String) {
        trayLogger.debug("📁 Tray: revealed \(name)")
    }
    
    static func trayItemCopiedPath(_ name: String) {
        trayLogger.debug("📁 Tray: copied path \(name)")
    }
    
    static func trayItemDropped(_ name: String) {
        trayLogger.info("📁 Tray: dropped \(name)")
    }
    
    static func trayAppLaunched(_ name: String) {
        trayLogger.info("🚀 Tray: launched app \(name)")
    }
    
    // MARK: - Permissions
    static func permissionRequested(_ resource: String) {
        permissionsLogger.info("🔐 Permission requested: \(resource)")
    }
    
    static func permissionGranted(_ resource: String) {
        permissionsLogger.info("✅ Permission granted: \(resource)")
    }
    
    static func permissionDenied(_ resource: String) {
        permissionsLogger.warning("❌ Permission denied: \(resource)")
    }
    
    // MARK: - Services
    static func serviceStarted(_ name: String) {
        servicesLogger.debug("▶️ Service started: \(name)")
    }
    
    static func serviceStopped(_ name: String) {
        servicesLogger.debug("⏹️ Service stopped: \(name)")
    }
    
    static func serviceError(_ name: String, error: Error) {
        servicesLogger.error("❌ Service error \(name): \(error.localizedDescription)")
    }
    
    // MARK: - Performance Warnings
    static func performanceWarning(_ msg: String) {
        appLogger.warning("⚠️ \(msg)")
    }
    
    static func memoryWarning(_ msg: String) {
        appLogger.warning("⚠️ Memory: \(msg)")
    }
}

// MARK: - In-Memory Ring Buffer for Diagnostics
class LogRingBuffer {
    private let capacity: Int
    private var buffer: [String] = []
    private let lock = NSLock()
    
    init(capacity: Int = 400) {
        self.capacity = capacity
    }
    
    func append(_ line: String) {
        lock.lock()
        defer { lock.unlock() }
        buffer.append(line)
        if buffer.count > capacity {
            buffer.removeFirst()
        }
    }
    
    func getAll() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return buffer
    }
    
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        buffer.removeAll()
    }
}

let logBuffer = LogRingBuffer(capacity: 400)
