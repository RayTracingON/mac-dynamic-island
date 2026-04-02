import Foundation
import os

/// Analytics and usage tracking manager (privacy-focused)
class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private let userDefaults = UserDefaults.standard
    private var sessionStart: Date?
    private var eventQueue: [AnalyticsEvent] = []
    
    private init() {
        loadState()
    }
    
    // MARK: - Session
    
    func startSession() {
        sessionStart = Date()
        incrementLaunchCount()
        trackEvent("session_start")
    }
    
    func endSession() {
        if let start = sessionStart {
            let duration = Date().timeIntervalSince(start)
            trackEvent("session_end", properties: ["duration": duration])
        }
        sessionStart = nil
        saveState()
    }
    
    // MARK: - Events
    
    func trackEvent(_ name: String, properties: [String: Any]? = nil) {
        guard isEnabled else { return }
        
        let event = AnalyticsEvent(
            name: name,
            properties: properties,
            timestamp: Date()
        )
        
        eventQueue.append(event)
        
        if eventQueue.count >= 10 {
            flushEvents()
        }
    }
    
    func trackScreen(_ screen: String) {
        trackEvent("screen_view", properties: ["screen": screen])
    }
    
    func trackAction(_ action: String, category: String? = nil) {
        var properties: [String: Any] = ["action": action]
        if let category = category {
            properties["category"] = category
        }
        trackEvent("user_action", properties: properties)
    }
    
    func trackError(_ error: Error, context: String? = nil) {
        var properties: [String: Any] = [
            "error": error.localizedDescription
        ]
        if let context = context {
            properties["context"] = context
        }
        trackEvent("error", properties: properties)
    }
    
    // MARK: - Features
    
    func trackFeatureUsage(_ feature: String) {
        incrementFeatureCount(feature)
        trackEvent("feature_used", properties: ["feature": feature])
    }
    
    func trackSettingChanged(_ setting: String, value: Any) {
        trackEvent("setting_changed", properties: [
            "setting": setting,
            "value": "\(value)"
        ])
    }
    
    // MARK: - Metrics
    
    private func incrementLaunchCount() {
        let key = "analytics_launch_count"
        let count = userDefaults.integer(forKey: key) + 1
        userDefaults.set(count, forKey: key)
    }
    
    private func incrementFeatureCount(_ feature: String) {
        let key = "analytics_feature_\(feature)"
        let count = userDefaults.integer(forKey: key) + 1
        userDefaults.set(count, forKey: key)
    }
    
    func getLaunchCount() -> Int {
        return userDefaults.integer(forKey: "analytics_launch_count")
    }
    
    func getFeatureCount(_ feature: String) -> Int {
        return userDefaults.integer(forKey: "analytics_feature_\(feature)")
    }
    
    // MARK: - Privacy
    
    private var isEnabled: Bool {
        return userDefaults.bool(forKey: "analytics_enabled")
    }
    
    func setEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: "analytics_enabled")
        if !enabled {
            clearData()
        }
    }
    
    func clearData() {
        eventQueue.removeAll()
        
        // Clear all analytics keys
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys where key.hasPrefix("analytics_") {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    // MARK: - Persistence
    
    private func flushEvents() {
        // In a real app, this would send events to analytics server
        // For privacy, we just log them locally
        let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "Analytics")
        logger.debug("Flushing \(self.eventQueue.count) analytics events")
        eventQueue.removeAll()
    }
    
    private func saveState() {
        flushEvents()
    }
    
    private func loadState() {
        // Load any persisted state if needed
    }
    
    // MARK: - Reports
    
    func generateUsageReport() -> UsageReport {
        return UsageReport(
            launchCount: getLaunchCount(),
            featuresUsed: getAllFeatureUsage(),
            lastSessionDate: sessionStart
        )
    }
    
    private func getAllFeatureUsage() -> [String: Int] {
        var usage: [String: Int] = [:]
        let keys = userDefaults.dictionaryRepresentation().keys
        
        for key in keys where key.hasPrefix("analytics_feature_") {
            let feature = key.replacingOccurrences(of: "analytics_feature_", with: "")
            usage[feature] = userDefaults.integer(forKey: key)
        }
        
        return usage
    }
}

// MARK: - Models

struct AnalyticsEvent {
    let name: String
    let properties: [String: Any]?
    let timestamp: Date
}

struct UsageReport {
    let launchCount: Int
    let featuresUsed: [String: Int]
    let lastSessionDate: Date?
    
    var mostUsedFeature: String? {
        return featuresUsed.max(by: { $0.value < $1.value })?.key
    }
}
