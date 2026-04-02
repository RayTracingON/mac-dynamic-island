import SwiftUI
import Combine
import AppKit


enum SneakPeekType {
    case brightness
    case volume
    case backlight
    case music
    case mic
    case battery
    case download
}

struct SneakPeek {
    var show: Bool = false
    var type: SneakPeekType = .music
    var value: CGFloat = 0
    var icon: String = ""
}

struct ExpandedItem {
    var show: Bool = false
    var type: SneakPeekType = .battery
    var value: CGFloat = 0
}

/// Enhanced view model with sneak peek and HUD functionality
@MainActor
class EnhancedBoringViewModel: ObservableObject {
    static let shared = EnhancedBoringViewModel()
    
    @Published var currentView: NotchViews = .home
    @Published var helloAnimationRunning: Bool = false
    @Published var sneakPeek: SneakPeek = SneakPeek()
    @Published var expandingView: ExpandedItem = ExpandedItem()
    @Published var optionKeyPressed: Bool = false
    
    @AppStorage("firstLaunch") var firstLaunch: Bool = true
    @AppStorage("hudReplacement") var hudReplacement: Bool = false
    @AppStorage("currentMicStatus") var currentMicStatus: Bool = true
    @AppStorage("musicLiveActivityEnabled") var musicLiveActivityEnabled: Bool = true
    
    private var sneakPeekTask: Task<Void, Never>?
    private var expandingViewTask: Task<Void, Never>?
    private var sneakPeekDuration: TimeInterval = 1.5
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        helloAnimationRunning = firstLaunch
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe screen brightness changes
        NotificationCenter.default.publisher(for: .screenBrightnessChanged)
            .sink { [weak self] notification in
                guard let value = notification.userInfo?["value"] as? Float else { return }
                self?.toggleSneakPeek(status: true, type: .brightness, value: CGFloat(value))
            }
            .store(in: &cancellables)
        
        // Observe keyboard brightness changes
        NotificationCenter.default.publisher(for: .keyboardBrightnessChanged)
            .sink { [weak self] notification in
                guard let value = notification.userInfo?["value"] as? Float else { return }
                self?.toggleSneakPeek(status: true, type: .backlight, value: CGFloat(value))
            }
            .store(in: &cancellables)
        
        // Observe volume changes
        NotificationCenter.default.publisher(for: .volumeChanged)
            .sink { [weak self] notification in
                guard let value = notification.userInfo?["value"] as? Float else { return }
                self?.toggleSneakPeek(status: true, type: .volume, value: CGFloat(value))
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Sneak Peek
    
    func toggleSneakPeek(
        status: Bool,
        type: SneakPeekType,
        duration: TimeInterval = 1.5,
        value: CGFloat = 0,
        icon: String = ""
    ) {
        sneakPeekDuration = duration
        
        if type != .music && !hudReplacement {
            return
        }
        
        withAnimation(.smooth) {
            sneakPeek.show = status
            sneakPeek.type = type
            sneakPeek.value = value
            sneakPeek.icon = icon
        }
        
        if type == .mic {
            currentMicStatus = value == 1
        }
        
        if status {
            scheduleSneakPeekHide(after: duration)
        }
    }
    
    private func scheduleSneakPeekHide(after duration: TimeInterval) {
        sneakPeekTask?.cancel()
        
        sneakPeekTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            
            withAnimation {
                toggleSneakPeek(status: false, type: .music)
                sneakPeekDuration = 1.5
            }
        }
    }
    
    // MARK: - Expanding View
    
    func toggleExpandingView(
        status: Bool,
        type: SneakPeekType,
        value: CGFloat = 0
    ) {
        withAnimation(.smooth) {
            expandingView.show = status
            expandingView.type = type
            expandingView.value = value
        }
        
        if status {
            scheduleExpandingViewHide(type: type)
        }
    }
    
    private func scheduleExpandingViewHide(type: SneakPeekType) {
        expandingViewTask?.cancel()
        
        let duration: TimeInterval = (type == .download ? 2 : 3)
        
        expandingViewTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            
            toggleExpandingView(status: false, type: type)
        }
    }
    
    // MARK: - View Navigation
    
    func showHome() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentView = .home
        }
    }
    
    func showShelf() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentView = .shelf
        }
    }
    
    func showMusic() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentView = .music
        }
    }
    
    func showCalendar() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentView = .calendar
        }
    }
    
    func showSettings() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentView = .settings
        }
    }
}

// MARK: - Volume Notification

extension Notification.Name {
    static let volumeChanged = Notification.Name("volumeChanged")
}
