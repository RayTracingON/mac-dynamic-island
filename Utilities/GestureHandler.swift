import Combine
import SwiftUI
import AppKit

/// Advanced gesture handling system for smooth interactions
class GestureHandler {
    static let shared = GestureHandler()
    
    private var activeGestures: [UUID: GestureState] = [:]
    private let hapticGenerator = NSHapticFeedbackManager.defaultPerformer
    
    private init() {}
    
    // MARK: - Gesture State
    
    struct GestureState {
        let id: UUID
        var startLocation: CGPoint
        var currentLocation: CGPoint
        var startTime: Date
        var velocity: CGVector
        var isDragging: Bool
        
        var distance: CGFloat {
            let dx = currentLocation.x - startLocation.x
            let dy = currentLocation.y - startLocation.y
            return sqrt(dx * dx + dy * dy)
        }
        
        var duration: TimeInterval {
            return Date().timeIntervalSince(startTime)
        }
        
        var angle: CGFloat {
            let dx = currentLocation.x - startLocation.x
            let dy = currentLocation.y - startLocation.y
            return atan2(dy, dx)
        }
    }
    
    // MARK: - Drag Gestures
    
    func handleDragStart(at location: CGPoint) -> UUID {
        let id = UUID()
        let state = GestureState(
            id: id,
            startLocation: location,
            currentLocation: location,
            startTime: Date(),
            velocity: .zero,
            isDragging: true
        )
        activeGestures[id] = state
        
        // Haptic feedback
        hapticGenerator.perform(.generic, performanceTime: .default)
        
        return id
    }
    
    func handleDragUpdate(id: UUID, at location: CGPoint) {
        guard var state = activeGestures[id] else { return }
        
        // Calculate velocity
        let dt = Date().timeIntervalSince(state.startTime)
        if dt > 0 {
            let dx = location.x - state.currentLocation.x
            let dy = location.y - state.currentLocation.y
            state.velocity = CGVector(dx: dx / dt, dy: dy / dt)
        }
        
        state.currentLocation = location
        activeGestures[id] = state
    }
    
    func handleDragEnd(id: UUID, at location: CGPoint) -> GestureState? {
        guard var state = activeGestures[id] else { return nil }
        
        state.currentLocation = location
        state.isDragging = false
        
        let finalState = state
        activeGestures.removeValue(forKey: id)
        
        return finalState
    }
    
    // MARK: - Swipe Detection
    
    func detectSwipe(state: GestureState, threshold: CGFloat = 50) -> SwipeDirection? {
        guard state.distance > threshold else { return nil }
        
        let angle = state.angle
        let radians = CGFloat.pi
        
        if angle > -radians/4 && angle <= radians/4 {
            return .right
        } else if angle > radians/4 && angle <= 3*radians/4 {
            return .down
        } else if angle > 3*radians/4 || angle <= -3*radians/4 {
            return .left
        } else {
            return .up
        }
    }
    
    enum SwipeDirection {
        case up, down, left, right
    }
    
    // MARK: - Pinch Gestures
    
    func handlePinch(magnification: CGFloat, velocity: CGFloat) -> PinchState {
        return PinchState(
            magnification: magnification,
            velocity: velocity,
            isExpanding: magnification > 1.0
        )
    }
    
    struct PinchState {
        let magnification: CGFloat
        let velocity: CGFloat
        let isExpanding: Bool
    }
    
    // MARK: - Long Press
    
    func handleLongPress(duration: TimeInterval = 0.5, tolerance: CGFloat = 10) -> Bool {
        return duration >= 0.5
    }
    
    // MARK: - Haptic Feedback
    
    func performHaptic(_ style: NSHapticFeedbackManager.FeedbackPattern = .generic) {
        hapticGenerator.perform(style, performanceTime: .default)
    }
    
    func performAlignmentHaptic() {
        hapticGenerator.perform(.alignment, performanceTime: .default)
    }
    
    func performLevelChangeHaptic() {
        hapticGenerator.perform(.levelChange, performanceTime: .default)
    }
}

// MARK: - SwiftUI Gesture Modifiers

extension View {
    func onDragGestureWithFeedback(
        minimumDistance: CGFloat = 10,
        onStart: @escaping (CGPoint) -> Void = { _ in },
        onUpdate: @escaping (CGPoint) -> Void,
        onEnd: @escaping (CGPoint, CGVector) -> Void
    ) -> some View {
        self.gesture(
            DragGesture(minimumDistance: minimumDistance)
                .onChanged { value in
                    onUpdate(value.location)
                }
                .onEnded { value in
                    let velocity = CGVector(
                        dx: value.predictedEndLocation.x - value.location.x,
                        dy: value.predictedEndLocation.y - value.location.y
                    )
                    onEnd(value.location, velocity)
                }
        )
    }
    
    func onLongPressWithHaptic(
        minimumDuration: Double = 0.5,
        action: @escaping () -> Void
    ) -> some View {
        self.onLongPressGesture(minimumDuration: minimumDuration) {
            GestureHandler.shared.performHaptic(.generic)
            action()
        }
    }
}
