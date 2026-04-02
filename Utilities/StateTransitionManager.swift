import SwiftUI
import Combine
import os

/// Manages smooth state transitions with animations
class StateTransitionManager: ObservableObject {
    static let shared = StateTransitionManager()
    
    @Published var currentState: String = "idle"
    @Published var isTransitioning = false
    
    private var transitionHandlers: [String: [String: TransitionHandler]] = [:]
    private var stateHistory: [StateHistoryItem] = []
    
    private init() {}
    
    // MARK: - State History
    
    struct StateHistoryItem {
        let from: String
        let to: String
        let timestamp: Date
        let duration: TimeInterval
    }
    
    // MARK: - Transition Handler
    
    struct TransitionHandler {
        let animation: Animation
        let duration: TimeInterval
        let prepare: (() -> Void)?
        let execute: () -> Void
        let complete: (() -> Void)?
    }
    
    // MARK: - Registration
    
    func registerTransition(
        from: String,
        to: String,
        animation: Animation = .spring(response: 0.4, dampingFraction: 0.75),
        duration: TimeInterval = 0.4,
        prepare: (() -> Void)? = nil,
        execute: @escaping () -> Void,
        complete: (() -> Void)? = nil
    ) {
        if transitionHandlers[from] == nil {
            transitionHandlers[from] = [:]
        }
        
        transitionHandlers[from]?[to] = TransitionHandler(
            animation: animation,
            duration: duration,
            prepare: prepare,
            execute: execute,
            complete: complete
        )
    }
    
    // MARK: - Transition Execution
    
    func transition(to newState: String) {
        guard !isTransitioning else {
            let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "StateTransition")
            logger.warning("Transition already in progress")
            return
        }
        
        let oldState = currentState
        guard let handler = transitionHandlers[oldState]?[newState] else {
            let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "StateTransition")
            logger.warning("No transition registered from \(oldState, privacy: .public) to \(newState, privacy: .public)")
            currentState = newState
            return
        }
        
        isTransitioning = true
        
        // Prepare
        handler.prepare?()
        
        // Execute with animation
        let startTime = Date()
        
        withAnimation(handler.animation) {
            handler.execute()
            currentState = newState
        }
        
        // Complete
        DispatchQueue.main.asyncAfter(deadline: .now() + handler.duration) {
            handler.complete?()
            self.isTransitioning = false
            
            // Record history
            let duration = Date().timeIntervalSince(startTime)
            self.recordTransition(from: oldState, to: newState, duration: duration)
        }
    }
    
    // MARK: - History
    
    private func recordTransition(from: String, to: String, duration: TimeInterval) {
        let item = StateHistoryItem(
            from: from,
            to: to,
            timestamp: Date(),
            duration: duration
        )
        
        stateHistory.append(item)
        
        // Keep only last 50 transitions
        if stateHistory.count > 50 {
            stateHistory.removeFirst()
        }
    }
    
    func getHistory() -> [StateHistoryItem] {
        return stateHistory
    }
    
    func clearHistory() {
        stateHistory.removeAll()
    }
    
    // MARK: - Predefined Transitions
    
    func setupNotchTransitions() {
        // Idle -> Compact
        registerTransition(
            from: "idle",
            to: "compact",
            animation: .spring(response: 0.35, dampingFraction: 0.7),
            duration: 0.35,
            prepare: {
                GestureHandler.shared.performHaptic(.generic)
            },
            execute: {
                // Scale and reveal
            },
            complete: {
                let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "StateTransition")
                logger.debug("Transitioned to compact")
            }
        )
        
        // Compact -> Expanded
        registerTransition(
            from: "compact",
            to: "expanded",
            animation: .spring(response: 0.4, dampingFraction: 0.75),
            duration: 0.4,
            prepare: {
                GestureHandler.shared.performLevelChangeHaptic()
            },
            execute: {
                // Expand animation
            }
        )
        
        // Expanded -> Compact
        registerTransition(
            from: "expanded",
            to: "compact",
            animation: .spring(response: 0.35, dampingFraction: 0.8),
            duration: 0.35,
            execute: {
                // Collapse animation
            }
        )
        
        // Compact -> Idle
        registerTransition(
            from: "compact",
            to: "idle",
            animation: .spring(response: 0.3, dampingFraction: 0.85),
            duration: 0.3,
            execute: {
                // Hide animation
            }
        )
    }
    
    // MARK: - State Machine
    
    func canTransition(from: String, to: String) -> Bool {
        return transitionHandlers[from]?[to] != nil
    }
    
    func getAvailableTransitions(from state: String) -> [String] {
        guard let keys = transitionHandlers[state]?.keys else { return [] }
        return Array(keys)
    }
}

// MARK: - SwiftUI Integration

extension View {
    func onStateChange<Value: Equatable>(
        of value: Value,
        transition: @escaping (Value) -> Void
    ) -> some View {
        self.onChange(of: value) { _, newValue in
            transition(newValue)
        }
    }
    
    func smoothStateTransition<T: Equatable>(
        value: T,
        animation: Animation = .spring(response: 0.4, dampingFraction: 0.75)
    ) -> some View {
        self.animation(animation, value: value)
    }
}
