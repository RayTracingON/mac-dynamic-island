import Foundation
import OSLog

/// Shared logger instance for UpdatedAppDelegate and other components
class Logger {
    static let shared = Logger()
    
    private let internalLogger: os.Logger
    
    private init() {
        self.internalLogger = os.Logger(subsystem: AppLogger.subsystem, category: "shared")
    }
    
    func info(_ message: String, category: String = "app") {
        let categoryLogger = os.Logger(subsystem: AppLogger.subsystem, category: category)
        categoryLogger.info("\(message)")
    }
    
    func debug(_ message: String, category: String = "app") {
        let categoryLogger = os.Logger(subsystem: AppLogger.subsystem, category: category)
        categoryLogger.debug("\(message)")
    }
    
    func error(_ message: String, category: String = "app") {
        let categoryLogger = os.Logger(subsystem: AppLogger.subsystem, category: category)
        categoryLogger.error("\(message)")
    }
    
    func warning(_ message: String, category: String = "app") {
        let categoryLogger = os.Logger(subsystem: AppLogger.subsystem, category: category)
        categoryLogger.warning("\(message)")
    }
}

struct AppLogger {
    static let subsystem = "com.maclingdonggao.overlay"

    // Modern Logger API (avoids NSXPCDecoder format string issues)
    private static let overlayLogger = os.Logger(subsystem: subsystem, category: "overlay")
    private static let inputLogger = os.Logger(subsystem: subsystem, category: "input")
    private static let trayLogger = os.Logger(subsystem: subsystem, category: "tray")
    private static let settingsLogger = os.Logger(subsystem: subsystem, category: "settings")
    private static let lifecycleLogger = os.Logger(subsystem: subsystem, category: "lifecycle")

    // MARK: - Overlay
    static func logOverlayShow() {
        overlayLogger.info("Overlay shown")
    }

    static func logOverlayHide() {
        overlayLogger.info("Overlay hidden")
    }

    static func logOverlayExpanded() {
        overlayLogger.info("Overlay expanded")
    }

    static func logOverlayCompacted() {
        overlayLogger.info("Overlay compacted")
    }

    // MARK: - Input
    static func logHotKeyPressed() {
        inputLogger.debug("Hotkey pressed (Option+Space)")
    }

    static func logHoverDetected() {
        inputLogger.debug("Hover detected")
    }

    static func logEscapePressed() {
        inputLogger.debug("ESC pressed, collapsing overlay")
    }

    static func logOutsideClickDetected() {
        inputLogger.debug("Outside click detected, collapsing overlay")
    }

    // MARK: - Tray
    static func logTrayItemAdded(fileName: String) {
        trayLogger.info("Tray item added: \(fileName)")
    }

    static func logTrayItemRemoved(id: String) {
        trayLogger.info("Tray item removed: \(id)")
    }

    static func logTrayItemMissing(fileName: String) {
        trayLogger.warning("Tray item missing: \(fileName)")
    }

    // MARK: - Settings
    static func logSettingChanged(key: String, value: String) {
        settingsLogger.info("Setting changed: \(key) = \(value)")
    }

    static func logLaunchAtLoginEnabled() {
        settingsLogger.info("Launch at login enabled")
    }

    static func logLaunchAtLoginDisabled() {
        settingsLogger.info("Launch at login disabled")
    }

    // MARK: - Lifecycle
    static func logAppDidFinishLaunching() {
        lifecycleLogger.info("App launched")
    }

    static func logAppWillTerminate() {
        lifecycleLogger.info("App terminating")
    }

    static func logScreenConfigChanged() {
        lifecycleLogger.info("Screen configuration changed")
    }

    static func logError(_ error: Error, context: String) {
        overlayLogger.error("Error in \(context): \(error.localizedDescription)")
    }
}
