import Foundation
import AppKit
import Combine
import os.log

final class SafeModeManager: ObservableObject {
    static var shared: SafeModeManager!
    
    static func configure(appState: AppState, hoverManager: HoverManager?) {
        shared = SafeModeManager(appState: appState, hoverManager: hoverManager)
    }
    
    @Published var isSafeMode: Bool = false {
        didSet {
            if isSafeMode {
                Log.performanceWarning("Safe mode: ENABLED")
                applyRestrictionsForSafeMode()
            } else {
                Log.performanceWarning("Safe mode: DISABLED")
                removeRestrictionsForSafeMode()
            }
        }
    }
    
    private weak var appState: AppState?
    private weak var hoverManager: HoverManager?
    
    init(appState: AppState, hoverManager: HoverManager?) {
        self.appState = appState
        self.hoverManager = hoverManager
        // Check if safe mode was previously enabled
        if UserDefaults.standard.bool(forKey: "safe_mode_enabled") {
            self.isSafeMode = true
        }
    }
    
    private func applyRestrictionsForSafeMode() {
        guard let appState = appState else { return }
        
        // Persist safe mode state
        UserDefaults.standard.set(true, forKey: "safe_mode_enabled")
        
        // Disable hover-to-open
        let originalHoverSetting = appState.settings.hoverToOpen
        if originalHoverSetting {
            appState.settings.hoverToOpen = false
            UserDefaults.standard.set(originalHoverSetting, forKey: "safe_mode_backup_hover")
        }
        
        // Stop the hover manager
        hoverManager?.stop()
        
        // Force reduce motion for safer behavior
        let originalMotionSetting = appState.settings.reduceMotion
        UserDefaults.standard.set(originalMotionSetting, forKey: "safe_mode_backup_motion")
        appState.settings.reduceMotion = true
        
        Log.performanceWarning("Safe mode: hover disabled, animations reduced")
    }
    
    private func removeRestrictionsForSafeMode() {
        guard let appState = appState else { return }
        
        // Persist safe mode state
        UserDefaults.standard.set(false, forKey: "safe_mode_enabled")
        
        // Restore hover-to-open if it was previously enabled
        if let wasEnabled = UserDefaults.standard.value(forKey: "safe_mode_backup_hover") as? Bool, wasEnabled {
            appState.settings.hoverToOpen = true
            UserDefaults.standard.removeObject(forKey: "safe_mode_backup_hover")
        }
        
        // Restore reduce motion setting
        if let wasEnabled = UserDefaults.standard.value(forKey: "safe_mode_backup_motion") as? Bool {
            appState.settings.reduceMotion = wasEnabled
            UserDefaults.standard.removeObject(forKey: "safe_mode_backup_motion")
        }
        
        // Restart the hover manager if hover is enabled
        if appState.settings.hoverToOpen {
            hoverManager?.start()
        }
        
        Log.performanceWarning("Safe mode: restrictions lifted")
    }
}
