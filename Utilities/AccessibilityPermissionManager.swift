import Cocoa
import OSLog

#if APP_STORE
/// Stub implementation for App Store builds
/// Accessibility features are not available in sandboxed apps
@MainActor
final class AccessibilityPermissionManager: ObservableObject {
    static let shared = AccessibilityPermissionManager()
    
    @Published private(set) var isAccessibilityEnabled: Bool = false
    @Published private(set) var hasPromptedUser: Bool = false
    
    private init() {}
    
    func checkAccessibilityStatus() {}
    @discardableResult
    func requestAccessibilityIfNeeded(force: Bool = false) -> Bool { false }
    func openAccessibilitySettings() {}
    func triggerSystemPrompt() {}
    func startMonitoring() {}
    func stopMonitoring() {}
    
    static var localizedStrings: [String: String] { [:] }
}
#else
/// Manages Accessibility permission status and user prompts.
/// Required for global hotkey monitoring and cross-app drag/drop.
@MainActor
final class AccessibilityPermissionManager: ObservableObject {
    
    static let shared = AccessibilityPermissionManager()
    
    private let logger = os.Logger(subsystem: AppLogger.subsystem, category: "AccessibilityPermission")
    
    // MARK: - Published State
    
    @Published private(set) var isAccessibilityEnabled: Bool = false
    @Published private(set) var hasPromptedUser: Bool = false
    
    // MARK: - UserDefaults Keys
    
    private let hasPromptedKey = "HasPromptedForAccessibility"
    private let lastCheckDateKey = "LastAccessibilityCheckDate"
    
    // MARK: - Initialization
    
    private init() {
        hasPromptedUser = UserDefaults.standard.bool(forKey: hasPromptedKey)
        checkAccessibilityStatus()
    }
    
    // MARK: - Public API
    
    /// Checks if Accessibility permission is currently granted
    func checkAccessibilityStatus() {
        isAccessibilityEnabled = AXIsProcessTrusted()
        logger.info("Accessibility status: \(self.isAccessibilityEnabled ? "Enabled" : "Disabled")")
    }
    
    /// Prompts user to enable Accessibility if not already enabled
    /// - Parameter force: If true, shows prompt even if previously shown
    /// - Returns: True if permission is already granted, false otherwise
    @discardableResult
    func requestAccessibilityIfNeeded(force: Bool = false) -> Bool {
        checkAccessibilityStatus()
        
        if isAccessibilityEnabled {
            logger.info("Accessibility already enabled")
            return true
        }
        
        // Check if we should prompt
        if !force && hasPromptedUser {
            // Only re-prompt once per day
            if let lastCheck = UserDefaults.standard.object(forKey: lastCheckDateKey) as? Date,
               Calendar.current.isDateInToday(lastCheck) {
                logger.debug("Already prompted today, skipping")
                return false
            }
        }
        
        showAccessibilityPrompt()
        return false
    }
    
    /// Opens System Settings to the Accessibility pane
    func openAccessibilitySettings() {
        logger.info("Opening Accessibility settings")
        
        // macOS 13+ uses System Settings
        if #available(macOS 13.0, *) {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        } else {
            // macOS 12 and earlier uses System Preferences
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    /// Triggers system prompt for Accessibility (shows system dialog)
    func triggerSystemPrompt() {
        logger.info("Triggering system accessibility prompt")
        
        // This triggers the system permission dialog
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Mark that we've prompted
        hasPromptedUser = true
        UserDefaults.standard.set(true, forKey: hasPromptedKey)
        UserDefaults.standard.set(Date(), forKey: lastCheckDateKey)
    }
    
    // MARK: - Private Methods
    
    private func showAccessibilityPrompt() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("accessibility_required_title", comment: "")
        alert.informativeText = NSLocalizedString("accessibility_required_message", comment: "")
        alert.alertStyle = .informational
        
        alert.addButton(withTitle: NSLocalizedString("open_settings", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("later", comment: ""))
        
        let response = alert.runModal()
        
        hasPromptedUser = true
        UserDefaults.standard.set(true, forKey: hasPromptedKey)
        UserDefaults.standard.set(Date(), forKey: lastCheckDateKey)
        
        if response == .alertFirstButtonReturn {
            triggerSystemPrompt()
            openAccessibilitySettings()
        }
    }
    
    // MARK: - Continuous Monitoring
    
    private var monitorTimer: Timer?
    
    /// Starts monitoring for accessibility permission changes
    func startMonitoring() {
        stopMonitoring()
        
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkAccessibilityStatus()
            }
        }
        
        logger.info("Started accessibility monitoring")
    }
    
    /// Stops monitoring for permission changes
    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }
}

// MARK: - Localized Strings

extension AccessibilityPermissionManager {
    
    /// Returns localized accessibility prompt strings
    static var localizedStrings: [String: String] {
        [
            "accessibility_required_title": NSLocalizedString("accessibility_required_title", comment: ""),
            "accessibility_required_message": NSLocalizedString("accessibility_required_message", comment: ""),
            "open_settings": NSLocalizedString("open_settings", comment: ""),
            "later": NSLocalizedString("later", comment: "")
        ]
    }
}
#endif
