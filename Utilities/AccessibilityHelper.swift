import AppKit
import Combine

/// Accessibility helper utilities
class AccessibilityHelper {
    static let shared = AccessibilityHelper()
    
    private init() {}
    
    // MARK: - Permission Checking
    
    func hasAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // MARK: - System Preferences
    
    func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    /// Polls for permission changes for 60 seconds or until granted
    func pollForPermission(completion: @escaping (Bool) -> Void) {
        var attempts = 0
        let maxAttempts = 60
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            attempts += 1
            if self.hasAccessibilityPermission() {
                timer.invalidate()
                completion(true)
            } else if attempts >= maxAttempts {
                timer.invalidate()
                completion(false)
            }
        }
    }
    
    var shouldReduceMotion: Bool {
        return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }
    
    var shouldDifferentiateWithoutColor: Bool {
        return NSWorkspace.shared.accessibilityDisplayShouldDifferentiateWithoutColor
    }
    
    var shouldIncreaseContrast: Bool {
        return NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    }
    
    var shouldReduceTransparency: Bool {
        return NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    }
    
    var isInvertColorsEnabled: Bool {
        return NSWorkspace.shared.accessibilityDisplayShouldInvertColors
    }
    
    // MARK: - UI Adjustments
    
    func animationDuration(_ default: TimeInterval) -> TimeInterval {
        return shouldReduceMotion ? 0 : `default`
    }
    
    func opacity(normal: Double, reduced: Double) -> Double {
        return shouldReduceTransparency ? reduced : normal
    }
    
    func contrast(normal: Double, increased: Double) -> Double {
        return shouldIncreaseContrast ? increased : normal
    }
    
    // MARK: - Notifications
    
    func observeAccessibilityChanges(_ observer: @escaping () -> Void) {
        let notifications: [NSWorkspace.AccessibilityDisplayOptionsDidChangeNotification] = [
            .reduceMotion,
            .differentiateWithoutColor,
            .increaseContrast,
            .reduceTransparency,
            .invertColors
        ]
        
        for notification in notifications {
            NotificationCenter.default.addObserver(
                forName: notification.rawValue,
                object: nil,
                queue: .main
            ) { _ in
                observer()
            }
        }
    }
}

// MARK: - Notification Extensions

extension NSWorkspace {
    enum AccessibilityDisplayOptionsDidChangeNotification {
        case reduceMotion
        case differentiateWithoutColor
        case increaseContrast
        case reduceTransparency
        case invertColors
        
        var rawValue: Notification.Name {
            switch self {
            case .reduceMotion:
                return NSWorkspace.accessibilityDisplayOptionsDidChangeNotification
            case .differentiateWithoutColor:
                return NSWorkspace.accessibilityDisplayOptionsDidChangeNotification
            case .increaseContrast:
                return NSWorkspace.accessibilityDisplayOptionsDidChangeNotification
            case .reduceTransparency:
                return NSWorkspace.accessibilityDisplayOptionsDidChangeNotification
            case .invertColors:
                return NSWorkspace.accessibilityDisplayOptionsDidChangeNotification
            }
        }
    }
}
