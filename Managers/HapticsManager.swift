import Cocoa

final class HapticsManager {
    static let shared = HapticsManager()
    
    private init() {}
    
    func play(_ type: NSHapticFeedbackManager.FeedbackPattern) {
        if SettingsDefaults.shared.get(SettingsDefaults.enableHaptics) {
            NSHapticFeedbackManager.defaultPerformer.perform(type, performanceTime: .default)
        }
    }
    
    /// Play a subtle click for UI interactions
    func playClick() {
        // specific 'alignment' feels like a nice click
        play(.alignment)
    }
    
    /// Play a stronger bump for mode changes or errors
    func playBump() {
        play(.levelChange)
    }
}
