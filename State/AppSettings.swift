import Foundation
import SwiftUI
import Combine
import ServiceManagement

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // Display mode (matches ScreenManager.DisplayMode)
    enum DisplayMode: String, CaseIterable {
        case mainOnly = "mainOnly"
        case activeOnly = "activeOnly"
        case allDisplays = "allDisplays"

        var localizedName: String {
            switch self {
            case .mainOnly:
                return L("settings.display.mode.main_only")
            case .activeOnly:
                return L("settings.display.mode.active")
            case .allDisplays:
                return L("settings.display.mode.all")
            }
        }
    }

    private let suite = UserDefaults.standard
    private let keysPrefix = "mac_lingdonggao_"

    // MARK: - Published Properties

    @Published var launchAtLogin: Bool {
        didSet { saveLaunchAtLogin(launchAtLogin) }
    }

    @Published var hoverToOpen: Bool {
        didSet { suite.set(hoverToOpen, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "hover_to_open")) }
    }

    @Published var displayMode: DisplayMode {
        didSet { suite.set(displayMode.rawValue, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "display_mode")) }
    }

    @Published var panelWidth: Double {
        didSet { 
            let clamped = AppSettings.clampPanelWidth(panelWidth)
            if clamped != panelWidth {
                panelWidth = clamped
            }
            suite.set(clamped, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "panel_width"))
        }
    }

    @Published var reduceMotion: Bool {
        didSet { suite.set(reduceMotion, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "reduce_motion")) }
    }

    @Published var showOnboarding: Bool {
        didSet { suite.set(showOnboarding, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "show_onboarding")) }
    }
    
    // Feature toggles
    @Published var dragDropEnabled: Bool {
        didSet { suite.set(dragDropEnabled, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "dragdrop_enabled")) }
    }
    
    @Published var mediaEnabled: Bool {
        didSet { suite.set(mediaEnabled, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "media_enabled")) }
    }
    
    @Published var clipboardEnabled: Bool {
        didSet { suite.set(clipboardEnabled, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "clipboard_enabled")) }
    }
    
    @Published var overlayScale: Double {
        didSet { suite.set(overlayScale, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "overlay_scale")) }
    }

    @Published var hoverDelay: Double {
        didSet { suite.set(hoverDelay, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "hover_delay")) }
    }

    @Published var hapticFeedback: Bool {
        didSet { suite.set(hapticFeedback, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "haptic_feedback")) }
    }

    @Published var alwaysShowTabs: Bool {
        didSet { suite.set(alwaysShowTabs, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "always_show_tabs")) }
    }

    @Published var lightingEffect: Bool {
        didSet { suite.set(lightingEffect, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "lighting_effect")) }
    }

    @Published var liveActivityEnabled: Bool {
        didSet { suite.set(liveActivityEnabled, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "live_activity_enabled")) }
    }

    @Published var sneakPeekEnabled: Bool {
        didSet { suite.set(sneakPeekEnabled, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "sneak_peek_enabled")) }
    }

    @Published var mediaInactivityTimeout: Double {
        didSet { suite.set(mediaInactivityTimeout, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "media_inactivity_timeout")) }
    }

    @Published var hudReplacementEnabled: Bool {
        didSet { suite.set(hudReplacementEnabled, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "hud_replacement_enabled")) }
    }

    @Published var batteryIndicatorEnabled: Bool {
        didSet { suite.set(batteryIndicatorEnabled, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "battery_indicator_enabled")) }
    }

    @Published var calendarEnabled: Bool {
        didSet { suite.set(calendarEnabled, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "calendar_enabled")) }
    }

    @Published var cornerRadiusScaling: Double {
        didSet { suite.set(cornerRadiusScaling, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "corner_radius_scaling")) }
    }

    // MARK: - Init

    private init() {
        let suite = UserDefaults.standard
        let prefix = "mac_lingdonggao_"
        let key: (String) -> String = { AppSettings.makeKey(prefix: prefix, name: $0) }

        let launchValue = suite.bool(forKey: key("launch_at_login"))
        let hoverValue = suite.bool(forKey: key("hover_to_open"))
        let modeString = suite.string(forKey: key("display_mode")) ?? DisplayMode.activeOnly.rawValue
        let widthValue = suite.double(forKey: key("panel_width"))
        let reduceMotionValue = suite.bool(forKey: key("reduce_motion"))
        let showOnboardingValue = suite.object(forKey: key("show_onboarding")) == nil ? true : suite.bool(forKey: key("show_onboarding"))
        
        let dragDropValue = suite.object(forKey: key("dragdrop_enabled")) == nil ? true : suite.bool(forKey: key("dragdrop_enabled"))
        let mediaValue = suite.object(forKey: key("media_enabled")) == nil ? true : suite.bool(forKey: key("media_enabled"))
        let clipboardValue = suite.object(forKey: key("clipboard_enabled")) == nil ? true : suite.bool(forKey: key("clipboard_enabled"))
        let overlayScaleValue = suite.double(forKey: key("overlay_scale"))
        
        let hoverDelayValue = suite.double(forKey: key("hover_delay"))
        let hapticValue = suite.object(forKey: key("haptic_feedback")) == nil ? true : suite.bool(forKey: key("haptic_feedback"))
        let showTabsValue = suite.bool(forKey: key("always_show_tabs"))
        let lightingValue = suite.object(forKey: key("lighting_effect")) == nil ? true : suite.bool(forKey: key("lighting_effect"))
        let liveActivityValue = suite.object(forKey: key("live_activity_enabled")) == nil ? true : suite.bool(forKey: key("live_activity_enabled"))
        let sneakPeekValue = suite.object(forKey: key("sneak_peek_enabled")) == nil ? true : suite.bool(forKey: key("sneak_peek_enabled"))
        let inactivityValue = suite.double(forKey: key("media_inactivity_timeout"))
        let hudReplacementValue = suite.object(forKey: key("hud_replacement_enabled")) == nil ? true : suite.bool(forKey: key("hud_replacement_enabled"))
        let batteryValue = suite.object(forKey: key("battery_indicator_enabled")) == nil ? true : suite.bool(forKey: key("battery_indicator_enabled"))
        let calendarValue = suite.object(forKey: key("calendar_enabled")) == nil ? true : suite.bool(forKey: key("calendar_enabled"))
        let radiusValue = suite.double(forKey: key("corner_radius_scaling"))

        self.launchAtLogin = launchValue
        self.hoverToOpen = hoverValue
        self.displayMode = DisplayMode(rawValue: modeString) ?? .activeOnly
        self.panelWidth = widthValue > 0 ? AppSettings.clampPanelWidth(widthValue) : 380.0
        self.reduceMotion = reduceMotionValue
        self.showOnboarding = showOnboardingValue
        self.dragDropEnabled = dragDropValue
        self.mediaEnabled = mediaValue
        self.clipboardEnabled = clipboardValue
        self.overlayScale = overlayScaleValue > 0 ? overlayScaleValue : 1.0
        self.hoverDelay = hoverDelayValue > 0 ? hoverDelayValue : 0.2
        self.hapticFeedback = hapticValue
        self.alwaysShowTabs = showTabsValue
        self.lightingEffect = lightingValue
        self.liveActivityEnabled = liveActivityValue
        self.sneakPeekEnabled = sneakPeekValue
        self.mediaInactivityTimeout = inactivityValue > 0 ? inactivityValue : 5.0
        self.hudReplacementEnabled = hudReplacementValue
        self.batteryIndicatorEnabled = batteryValue
        self.calendarEnabled = calendarValue
        self.cornerRadiusScaling = radiusValue > 0 ? radiusValue : 1.0
    }

    // MARK: - Helpers

    static func makeKey(prefix: String, name: String) -> String {
        prefix + name
    }

    static func clampPanelWidth(_ width: Double) -> Double {
        max(300, min(500, width))
    }

    private func saveLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                suite.set(enabled, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "launch_at_login"))
            } catch {
                print("Error updating launch at login: \(error)")
                launchAtLogin = !enabled
            }
        } else {
            suite.set(enabled, forKey: AppSettings.makeKey(prefix: keysPrefix, name: "launch_at_login"))
        }
    }

    func shouldUseReducedMotion() -> Bool {
        if reduceMotion {
            return true
        }
        if #available(macOS 12, *) {
            return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        }
        return false
    }
}
