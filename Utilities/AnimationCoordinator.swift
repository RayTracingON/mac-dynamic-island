import SwiftUI
import Combine

/// Advanced animation coordinator for synchronized complex animations
class AnimationCoordinator: ObservableObject {
    static let shared = AnimationCoordinator()
    
    @Published var isAnimating = false
    
    private var runningAnimations: [String: AnimationSequence] = [:]
    
    private init() {}
    
    // MARK: - Animation Sequence
    
    struct AnimationSequence {
        let id: String
        var steps: [AnimationStep]
        var currentStep: Int = 0
        var isRunning: Bool = true
        
        struct AnimationStep {
            let duration: TimeInterval
            let delay: TimeInterval
            let animation: Animation
            let action: () -> Void
        }
    }
    
    // MARK: - Orchestration
    
    func runSequence(
        id: String,
        steps: [(duration: TimeInterval, delay: TimeInterval, animation: Animation, action: () -> Void)]
    ) {
        let animationSteps = steps.map { step in
            AnimationSequence.AnimationStep(
                duration: step.duration,
                delay: step.delay,
                animation: step.animation,
                action: step.action
            )
        }
        
        let sequence = AnimationSequence(
            id: id,
            steps: animationSteps
        )
        
        runningAnimations[id] = sequence
        executeNextStep(for: id)
    }
    
    private func executeNextStep(for id: String) {
        guard var sequence = runningAnimations[id],
              sequence.currentStep < sequence.steps.count else {
            runningAnimations.removeValue(forKey: id)
            return
        }
        
        let step = sequence.steps[sequence.currentStep]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + step.delay) {
            withAnimation(step.animation) {
                step.action()
            }
            
            sequence.currentStep += 1
            self.runningAnimations[id] = sequence
            
            DispatchQueue.main.asyncAfter(deadline: .now() + step.duration) {
                self.executeNextStep(for: id)
            }
        }
    }
    
    func cancelSequence(id: String) {
        runningAnimations.removeValue(forKey: id)
    }
    
    func cancelAllSequences() {
        runningAnimations.removeAll()
    }
    
    // MARK: - Predefined Sequences
    
    func expandNotch(completion: @escaping () -> Void) {
        runSequence(id: "expandNotch", steps: [
            (0.15, 0, .easeOut, { /* Scale up */ }),
            (0.3, 0.05, .spring(response: 0.4, dampingFraction: 0.7), { /* Full expand */ }),
            (0.1, 0, .easeIn, completion)
        ])
    }
    
    func collapseNotch(completion: @escaping () -> Void) {
        runSequence(id: "collapseNotch", steps: [
            (0.2, 0, .easeIn, { /* Start collapse */ }),
            (0.25, 0, .spring(response: 0.35, dampingFraction: 0.8), { /* Shrink */ }),
            (0.1, 0, .easeOut, completion)
        ])
    }
    
    func bounceEffect(view: AnyHashable, completion: @escaping () -> Void) {
        runSequence(id: "bounce-\(view)", steps: [
            (0.1, 0, .spring(response: 0.2, dampingFraction: 0.5), { /* Bounce up */ }),
            (0.15, 0, .spring(response: 0.3, dampingFraction: 0.6), { /* Bounce back */ }),
            (0.1, 0, .easeOut, completion)
        ])
    }
    
    // MARK: - Advanced Transitions
    
    func morphTransition(
        from: CGSize,
        to: CGSize,
        duration: TimeInterval = 0.4,
        completion: @escaping () -> Void
    ) {
        let steps = stride(from: 0.0, through: 1.0, by: 0.1).map { progress in
            let _ = CGSize(
                width: from.width + (to.width - from.width) * progress,
                height: from.height + (to.height - from.height) * progress
            )
            return (
                duration: duration / 10,
                delay: 0.0,
                animation: Animation.spring(response: 0.3, dampingFraction: 0.75),
                action: { /* Apply size: \(size) */ }
            )
        }
        
        runSequence(id: "morph", steps: steps + [(0.1, 0, .easeOut, completion)])
    }
    
    // MARK: - Easing Functions
    
    static func easeInOutCubic(_ t: Double) -> Double {
        return t < 0.5
            ? 4 * t * t * t
            : 1 - pow(-2 * t + 2, 3) / 2
    }
    
    static func easeInOutQuad(_ t: Double) -> Double {
        return t < 0.5
            ? 2 * t * t
            : 1 - pow(-2 * t + 2, 2) / 2
    }
    
    static func elasticOut(_ t: Double) -> Double {
        let c4 = (2 * Double.pi) / 3
        return t == 0 ? 0 : (t == 1 ? 1 : pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + 1)
    }
}

// MARK: - SwiftUI Integration

extension View {
    func animateWithCoordinator(
        id: String,
        isActive: Bool,
        animation: Animation = .spring(),
        action: @escaping () -> Void
    ) -> some View {
        self.onChange(of: isActive) { _, active in
            if active {
                withAnimation(animation) {
                    action()
                }
            }
        }
    }
    
    func morphingTransition(isExpanded: Bool) -> some View {
        self
            .scaleEffect(isExpanded ? 1.0 : 0.95)
            .opacity(isExpanded ? 1.0 : 0.8)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isExpanded)
    }
}
