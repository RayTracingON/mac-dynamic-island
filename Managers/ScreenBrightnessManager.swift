import Foundation
import Combine

/// Manager for screen brightness control via XPC
class ScreenBrightnessManager: ObservableObject {
    static let shared = ScreenBrightnessManager()
    
    @Published var currentBrightness: Float = 0.5
    @Published var isAvailable: Bool = false
    
    private var monitoringTask: Task<Void, Never>?
    
    private init() {
        Task {
            await checkAvailability()
            await updateBrightness()
        }
    }
    
    func start() {
        monitoringTask?.cancel()
        monitoringTask = Task {
            while !Task.isCancelled {
                await updateBrightness()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }
    
    func stop() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    private func checkAvailability() async {
        let available = await XPCHelperClient.shared.isScreenBrightnessAvailable()
        await MainActor.run {
            isAvailable = available
        }
    }
    
    private func updateBrightness() async {
        guard let brightness = await XPCHelperClient.shared.currentScreenBrightness() else {
            return
        }
        
        await MainActor.run {
            currentBrightness = brightness
        }
    }
    
    func setBrightness(_ value: Float) async {
        let clamped = max(0, min(1, value))
        let success = await XPCHelperClient.shared.setScreenBrightness(clamped)
        
        if success {
            await MainActor.run {
                currentBrightness = clamped
            }
            
            // Notify coordinator for HUD
            NotificationCenter.default.post(
                name: .screenBrightnessChanged,
                object: nil,
                userInfo: ["value": clamped]
            )
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let screenBrightnessChanged = Notification.Name("screenBrightnessChanged")
    static let accessibilityAuthorizationChanged = Notification.Name("accessibilityAuthorizationChanged")
    static let selectedScreenChanged = Notification.Name("selectedScreenChanged")
}
