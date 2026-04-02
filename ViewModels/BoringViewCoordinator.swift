//
//  BoringViewCoordinator.swift
//  Mac灵动岛
//
//  Stage 1: Central coordinator from boringNotch
//

import SwiftUI
import Combine

class BoringViewCoordinator: ObservableObject {
    static let shared = BoringViewCoordinator()
    
    // MARK: - Published Properties
    
    @Published var currentView: NotchViews = .home
    @Published var firstLaunch: Bool = false
    @Published var helloAnimationRunning: Bool = false
    @Published var selectedScreenUUID: String = ""
    @Published var preferredScreenUUID: String? = nil
    @Published var alwaysShowTabs: Bool = false
    
    // MARK: - Sneak Peek State
    
    struct SneakPeekState {
        var show: Bool = false
        var type: SneakContentType = .none
        var value: CGFloat = 0
        var icon: String = ""
    }
    
    @Published var sneakPeek = SneakPeekState()
    
    // MARK: - Expanding View State
    
    struct ExpandingViewState {
        var show: Bool = false
        var type: SneakContentType = .none
    }
    
    @Published var expandingView = ExpandingViewState()
    
    // MARK: - Feature Flags
    
    @Published var musicLiveActivityEnabled: Bool = true
    
    // MARK: - Initialization
    
    private init() {
        // Check if first launch
        if !UserDefaults.standard.bool(forKey: "has_launched_before") {
            firstLaunch = true
            helloAnimationRunning = true
            UserDefaults.standard.set(true, forKey: "has_launched_before")
        }
        
        // Set initial screen UUID to main screen
        if let mainScreen = NSScreen.main,
           let uuid = mainScreen.displayUUID {
            selectedScreenUUID = uuid
        }
    }
    
    // MARK: - Sneak Peek Control
    
    func toggleSneakPeek(status: Bool, type: SneakContentType, value: CGFloat = 0, icon: String = "", duration: TimeInterval = 2.0) {
        sneakPeek.show = status
        sneakPeek.type = type
        sneakPeek.value = value
        sneakPeek.icon = icon
        
        if status {
            // Auto-hide after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                self?.sneakPeek.show = false
            }
        }
    }
    
    // MARK: - Expanding View Control
    
    func toggleExpandingView(status: Bool, type: SneakContentType) {
        expandingView.show = status
        expandingView.type = type
    }
}
