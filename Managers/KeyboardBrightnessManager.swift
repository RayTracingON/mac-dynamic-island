import Foundation
import Combine

#if APP_STORE
/// Stub implementation for App Store builds
class KeyboardBrightnessManager: ObservableObject {
    static let shared = KeyboardBrightnessManager()
    
    @Published var currentBrightness: Float = 0.5
    @Published var isAvailable: Bool = false
    
    private init() {}
    
    func start() {}
    func stop() {}
    func setBrightness(_ value: Float) async {}
}
#else
/// Manager for keyboard brightness control via XPC (wrapper for KeyboardBacklightManager)
/// Note: Depends on KeyboardBacklightManager which uses IOKit
class KeyboardBrightnessManager: ObservableObject {
    static let shared = KeyboardBrightnessManager()
    
    @Published var currentBrightness: Float = 0.5
    @Published var isAvailable: Bool = false
    
    private let backlightManager = KeyboardBacklightManager.shared
    private var monitoringTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Subscribe to backlight manager changes
        backlightManager.$brightness
            .sink { [weak self] value in
                self?.currentBrightness = Float(value)
            }
            .store(in: &cancellables)
        
        backlightManager.$isAvailable
            .sink { [weak self] value in
                self?.isAvailable = value
            }
            .store(in: &cancellables)
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
    
    private func updateBrightness() async {
        backlightManager.updateBrightness()
    }
    
    func setBrightness(_ value: Float) async {
        backlightManager.setBrightness(Double(value))
        
        // Notify coordinator for HUD
        NotificationCenter.default.post(
            name: .keyboardBrightnessChanged,
            object: nil,
            userInfo: ["value": value]
        )
    }
}

#endif

// MARK: - Notification Names
extension Notification.Name {
    static let keyboardBrightnessChanged = Notification.Name("keyboardBrightnessChanged")
}
