import Combine
import Foundation
import AppKit

/// Manager for system-level preferences and settings
class SystemPreferencesManager {
    static let shared = SystemPreferencesManager()
    
    private init() {}
    
    // MARK: - Appearance
    
    var isDarkMode: Bool {
        let appearance = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
        return appearance == "Dark"
    }
    
    var accentColor: NSColor {
        return NSColor.controlAccentColor
    }
    
    func observeAppearanceChanges(handler: @escaping (Bool) -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            handler(self?.isDarkMode ?? false)
        }
    }
    
    // MARK: - Accessibility
    
    var isReduceMotionEnabled: Bool {
        return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
    
    var isReduceTransparencyEnabled: Bool {
        return NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    }
    
    var isIncreaseContrastEnabled: Bool {
        return NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    }
    
    var isDifferentiateWithoutColorEnabled: Bool {
        return NSWorkspace.shared.accessibilityDisplayShouldDifferentiateWithoutColor
    }
    
    // MARK: - System Info
    
    var osVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
    
    var computerName: String {
        return Host.current().localizedName ?? "Mac"
    }
    
    var userName: String {
        return NSFullUserName()
    }
    
    var isOnBattery: Bool {
        // Would check IOKit power source
        return false
    }
    
    // MARK: - Display
    
    var mainScreenSize: CGSize {
        return NSScreen.main?.frame.size ?? .zero
    }
    
    var hasNotch: Bool {
        guard let screen = NSScreen.main else { return false }
        return screen.safeAreaInsets.top > 0
    }
    
    var notchHeight: CGFloat {
        guard let screen = NSScreen.main else { return 0 }
        return screen.safeAreaInsets.top
    }
    
    // MARK: - Locale
    
    var currentLocale: Locale {
        return Locale.current
    }
    
    var preferredLanguages: [String] {
        return Locale.preferredLanguages
    }
    
    var is24HourFormat: Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let dateString = formatter.string(from: Date())
        return dateString.contains("AM") || dateString.contains("PM") ? false : true
    }
    
    // MARK: - Permissions
    
    func openSystemPreferences(pane: String) {
        let url = URL(string: "x-apple.systempreferences:\(pane)")!
        NSWorkspace.shared.open(url)
    }
    
    func openSecurityPrivacyPreferences() {
        openSystemPreferences(pane: "com.apple.preference.security?Privacy")
    }
    
    func openAccessibilityPreferences() {
        openSystemPreferences(pane: "com.apple.preference.universalaccess")
    }
    
    func openNotificationsPreferences() {
        openSystemPreferences(pane: "com.apple.preference.notifications")
    }
}
