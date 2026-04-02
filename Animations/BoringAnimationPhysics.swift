//
//  BoringAnimationPhysics.swift
//  Mac灵动岛
//
//  Reverse-engineered from Boring.notch codebase
//  This file contains the EXACT animation physics parameters extracted from the source
//
//  Created by Animation Extraction on 2026-01-24
//

import SwiftUI
import AppKit
import Combine

// MARK: - Core Animation Constants
// Source: boring.notch/boringNotch/animations/drop.swift

/// The central animation library extracted from Boring.notch
/// This class provides the EXACT animation curves used in the original app
public class BoringAnimations {
    
    // MARK: - Primary Animation
    // Source: drop.swift line 19-24
    // The main animation used for most state transitions
    var animation: Animation {
        if #available(macOS 14.0, *) {
            // macOS 14+: Uses bouncy spring with 0.4s duration
            // This creates the signature "alive" feel
            Animation.spring(.bouncy(duration: 0.4))
        } else {
            // Fallback: Custom bezier timing curve (0.16, 1, 0.3, 1)
            // This is an "ease-out-expo" style curve for older macOS
            Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.7)
        }
    }
}

// MARK: - Interactive Spring Constants
// Source: boring.notch/boringNotch/ContentView.swift line 41

/// The shared interactive spring used for ALL movement/resizing
/// This is the "magnetic" feel that makes interactions feel connected
/// 
/// Parameters extracted:
/// - response: 0.38 (how quickly the spring responds)
/// - dampingFraction: 0.8 (controls oscillation - 0.8 is slightly underdamped)
/// - blendDuration: 0 (instant blend between animations)
let boringInteractiveSpring = Animation.interactiveSpring(
    response: 0.38,
    dampingFraction: 0.8,
    blendDuration: 0
)

// MARK: - State Transition Springs
// Source: boring.notch/boringNotch/ContentView.swift lines 123-124

/// Opening animation spring - slightly faster response
/// Used when the notch expands from compact to open state
let boringOpenAnimation = Animation.spring(
    response: 0.42,          // Slightly slower than interactive
    dampingFraction: 0.8,    // Same damping maintains consistency
    blendDuration: 0
)

/// Closing animation spring - higher damping for controlled return
/// Used when the notch contracts from open to compact state
let boringCloseAnimation = Animation.spring(
    response: 0.45,          // Slightly slower for smooth settle
    dampingFraction: 1.0,    // Critical damping - no oscillation
    blendDuration: 0
)

// MARK: - Corner Radius Insets
// Source: boring.notch/boringNotch/sizing/matters.swift line 18

/// The exact corner radius values used for the notch shape
/// These create the signature Apple Dynamic Island look
struct CornerRadiusInsets {
    struct State {
        let top: CGFloat
        let bottom: CGFloat
    }
    
    /// Opened state: Larger, rounder corners
    static let opened = State(top: 19, bottom: 24)
    
    /// Closed state: Tighter, more compact corners
    static let closed = State(top: 6, bottom: 14)
}

// MARK: - Album Art Corner Radius
// Source: boring.notch/boringNotch/sizing/matters.swift lines 20-23

enum MusicPlayerImageSizes {
    static let cornerRadiusInset: (opened: CGFloat, closed: CGFloat) = (opened: 13.0, closed: 4.0)
    static let size: (opened: CGSize, closed: CGSize) = (
        opened: CGSize(width: 90, height: 90),
        closed: CGSize(width: 20, height: 20)
    )
}

// MARK: - Gesture Physics
// Source: boring.notch/boringNotch/ContentView.swift lines 560-608

/// Gesture progress calculation formula:
/// gestureProgress = (translation / gestureSensitivity) * 20
/// 
/// This creates the "physical" resistance feel when dragging
/// The factor of 20 provides enough visual feedback without over-response
struct GesturePhysics {
    
    /// Calculate the gesture progress for visual feedback
    /// - Parameters:
    ///   - translation: Raw drag translation in points
    ///   - sensitivity: User-configured sensitivity (default: 20)
    ///   - direction: 1 for down gesture, -1 for up gesture
    /// - Returns: Progress value that can be used for scale/opacity effects
    static func calculateProgress(
        translation: CGFloat,
        sensitivity: CGFloat = 20,
        direction: CGFloat = 1
    ) -> CGFloat {
        return (translation / sensitivity) * 20 * direction
    }
    
    /// Calculate the scale factor from gesture progress
    /// Source: ContentView.swift lines 85-88
    /// 
    /// Formula: 1.0 + gestureProgress * 0.01, clamped to min 0.6
    /// This creates the "squishy" physics when dragging
    static func calculateScale(from gestureProgress: CGFloat) -> CGFloat {
        guard gestureProgress != 0 else { return 1.0 }
        let scaleFactor = 1.0 + gestureProgress * 0.01
        return max(0.6, scaleFactor)
    }
    
    /// Calculate opacity during gesture
    /// Source: ContentView.swift line 296
    /// 
    /// Formula: 1.0 - min(abs(gestureProgress) * 0.1, 0.3)
    /// Provides subtle fade during interaction
    static func calculateOpacity(from gestureProgress: CGFloat) -> CGFloat {
        guard gestureProgress != 0 else { return 1.0 }
        return 1.0 - min(abs(gestureProgress) * 0.1, 0.3)
    }
}

// MARK: - Slider Drag Animation
// Source: boring.notch/boringNotch/components/Notch/NotchHomeView.swift line 575

/// Spring used for slider drag feedback
/// Lower response and damping than main springs for snappier control feel
let sliderDragSpring = Animation.spring(
    response: 0.35,
    dampingFraction: 0.7
)

// MARK: - Button Bounce Animation
// Source: boring.notch/boringNotch/extensions/Button+Bouncing.swift line 24

/// Spring for button press/release bounce effect
/// Very low damping creates the signature "bouncy" button feel
let buttonBounceSpring = Animation.spring(
    response: 0.3,
    dampingFraction: 0.3,
    blendDuration: 0.3
)

// MARK: - Hover/Selection Animation
// Source: boring.notch/boringNotch/components/Onboarding/MusicControllerSelectionView.swift line 88

/// Spring for hover and selection effects
/// Balanced between responsiveness and smoothness
let hoverSelectionSpring = Animation.spring(
    response: 0.3,
    dampingFraction: 0.6
)

// MARK: - Drop Zone Animation
// Source: boring.notch/boringNotch/components/Shelf/Views/FileShareView.swift line 84

/// Spring for drop zone targeting feedback
let dropZoneSpring = Animation.spring(
    response: 0.36,
    dampingFraction: 0.7
)

// MARK: - Smooth Animation Variants
// Source: Various files using .smooth

/// Standard smooth animation for state changes
/// Used when spring physics would be too "bouncy"
let boringSmooth = Animation.smooth

/// Smooth animation with specific duration
/// Source: SystemEventIndicatorModifier.swift line 136
let boringSmoothDuration = Animation.smooth(duration: 0.3)

// MARK: - Easing Animations
// Source: OnboardingView.swift, NotchHomeView.swift

/// Standard ease in-out for longer transitions
let boringEaseInOut = Animation.easeInOut(duration: 0.6)

/// Fast ease in-out for quick state changes
/// Source: NotchHomeView.swift line 342
let boringFastEaseInOut = Animation.easeInOut(duration: 0.12)

/// Medium ease in-out for volume/control toggles
/// Source: NotchHomeView.swift line 385
let boringMediumEaseInOut = Animation.easeInOut(duration: 0.2)

// MARK: - Pan Gesture Direction
// Source: boring.notch/boringNotch/extensions/PanGesture.swift

enum PanDirection {
    case left, right, up, down
    
    var isHorizontal: Bool { self == .left || self == .right }
    var sign: CGFloat { (self == .right || self == .down) ? 1 : -1 }
    
    /// Extract signed translation from a gesture
    func signed(from translation: CGSize) -> CGFloat {
        (isHorizontal ? translation.width : translation.height) * sign
    }
    
    /// Extract signed delta from scroll event
    func signed(deltaX: CGFloat, deltaY: CGFloat) -> CGFloat {
        (isHorizontal ? deltaX : deltaY) * sign
    }
}

// MARK: - Pan Gesture View Extension
// Source: boring.notch/boringNotch/extensions/PanGesture.swift lines 21-35

extension View {
    /// Adds a pan gesture with physics-based feedback
    /// 
    /// This is the EXACT implementation from Boring.notch that creates
    /// the magnetic, interruptible gesture tracking
    ///
    /// - Parameters:
    ///   - direction: Which direction triggers the gesture
    ///   - threshold: Minimum movement before activation (default: 4 points)
    ///   - action: Callback with translation magnitude and phase
    func panGesture(
        direction: PanDirection,
        threshold: CGFloat = 4,
        action: @escaping (CGFloat, NSEvent.Phase) -> Void
    ) -> some View {
        self
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let s = direction.signed(from: value.translation)
                        guard s > 0, s.magnitude >= threshold else { return }
                        action(s.magnitude, .changed)
                    }
                    .onEnded { _ in action(0, .ended) }
            )
            .background(ScrollMonitor(direction: direction, threshold: threshold, action: action))
    }
}

// MARK: - Scroll Monitor (Trackpad Support)
// Source: boring.notch/boringNotch/extensions/PanGesture.swift lines 37-145

/// Monitors scroll wheel/trackpad events for gesture detection
/// This enables the smooth trackpad two-finger swipe gestures
private struct ScrollMonitor: NSViewRepresentable {
    let direction: PanDirection
    let threshold: CGFloat
    let action: (CGFloat, NSEvent.Phase) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.installMonitor(on: view)
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.removeMonitor()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(direction: direction, threshold: threshold, action: action)
    }
    
    @MainActor final class Coordinator: NSObject {
        private let direction: PanDirection
        private let threshold: CGFloat
        private let action: (CGFloat, NSEvent.Phase) -> Void
        private var monitor: Any?
        private var accumulated: CGFloat = 0
        private var active = false
        private var endTask: Task<Void, Never>?
        
        // Noise threshold filters out micro-movements
        // Source: PanGesture.swift line 62
        private let noiseThreshold: CGFloat = 0.2
        
        // Axis dominance factor ensures intentional swipes
        // Source: PanGesture.swift line 123
        private let axisDominanceFactor: CGFloat = 1.5
        
        init(direction: PanDirection, threshold: CGFloat, action: @escaping (CGFloat, NSEvent.Phase) -> Void) {
            self.direction = direction
            self.threshold = threshold
            self.action = action
        }
        
        private func scheduleEndTimeout() {
            endTask?.cancel()
            endTask = Task { @MainActor in
                // 300ms timeout for gesture end detection
                // Source: PanGesture.swift line 75
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                if active {
                    action(accumulated.magnitude, .ended)
                } else {
                    action(0, .ended)
                }
                active = false
                accumulated = 0
            }
        }
        
        func installMonitor(on view: NSView) {
            removeMonitor()
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { [weak self, weak view] event in
                guard let self = self, event.window === view?.window else { return event }
                self.handleScroll(event)
                return event
            }
        }
        
        func removeMonitor() {
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
            accumulated = 0
            active = false
            endTask?.cancel()
            endTask = nil
        }
        
        private func handleScroll(_ event: NSEvent) {
            // Check for gesture end
            if event.phase == .ended || event.momentumPhase == .ended {
                if active {
                    action(accumulated.magnitude, .ended)
                } else {
                    action(0, .ended)
                }
                active = false
                accumulated = 0
                return
            }
            
            // Axis dominance check - prevents diagonal movement triggering
            let absDX = abs(event.scrollingDeltaX)
            let absDY = abs(event.scrollingDeltaY)
            let isAxisDominant: Bool = direction.isHorizontal
                ? (absDX >= axisDominanceFactor * absDY)
                : (absDY >= axisDominanceFactor * absDX)
            guard isAxisDominant else { return }
            
            // Scale non-precise (mouse wheel) scrolling
            // Factor of 8 makes mouse wheel feel like trackpad
            // Source: PanGesture.swift line 130
            let raw = direction.signed(deltaX: event.scrollingDeltaX, deltaY: event.scrollingDeltaY)
            let scale: CGFloat = event.hasPreciseScrollingDeltas ? 1 : 8
            let s = raw * scale
            
            guard s.magnitude > noiseThreshold else { return }
            
            // Accumulate only positive movement in gesture direction
            accumulated = s > 0 ? accumulated + s : 0
            
            // Activate once threshold is reached
            if !active && accumulated >= threshold {
                active = true
                action(accumulated.magnitude, .began)
            } else if active {
                action(accumulated.magnitude, .changed)
            }
            
            scheduleEndTimeout()
        }
    }
}

// MARK: - Bouncing Button Style
// Source: boring.notch/boringNotch/extensions/Button+Bouncing.swift

/// Button style that creates the signature bounce effect
/// Scale: 1.0 -> 0.9 on press with bouncy spring
struct BouncingButtonStyle: ButtonStyle {
    @State private var isPressed = false
    var cornerRadius: CGFloat = 10
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(red: 20/255, green: 20/255, blue: 20/255))
                    .strokeBorder(.white.opacity(0.04), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .onChange(of: configuration.isPressed) { _, newValue in
                // Uses buttonBounceSpring: response 0.3, damping 0.3
                withAnimation(buttonBounceSpring) {
                    isPressed = newValue
                }
            }
    }
}

extension Button {
    func bouncingStyle(cornerRadius: CGFloat = 10) -> some View {
        self.buttonStyle(BouncingButtonStyle(cornerRadius: cornerRadius))
    }
}

// MARK: - Conditional Modifier Extension
// Note: conditionalModifier is already defined in Extensions/View+Extensions.swift
// Removed duplicate definition to avoid redeclaration error

// MARK: - Animation Namespace Singleton
// For matchedGeometryEffect consistency across views

final class AnimationNamespaceProvider: ObservableObject {
    static let shared = AnimationNamespaceProvider()
    
    // Add a published property to satisfy ObservableObject protocol
    @Published var animationTrigger: Bool = false
    
    private init() {}
    
    /// Call this to trigger animation updates
    func triggerUpdate() {
        animationTrigger.toggle()
    }
}

// MARK: - Usage Summary Comment
/*
 ============================================================
 BORING.NOTCH ANIMATION PHYSICS - USAGE GUIDE
 ============================================================
 
 1. MAIN STATE TRANSITIONS (open/close):
    Use `boringOpenAnimation` for expanding
    Use `boringCloseAnimation` for contracting
 
 2. INTERACTIVE GESTURES:
    Use `boringInteractiveSpring` for all gesture-driven animations
    This maintains the "connected" feel during user interaction
 
 3. GESTURE PROGRESS CALCULATION:
    let progress = GesturePhysics.calculateProgress(translation: value)
    let scale = GesturePhysics.calculateScale(from: progress)
    let opacity = GesturePhysics.calculateOpacity(from: progress)
 
 4. HOVER/SELECTION STATES:
    Use `hoverSelectionSpring` for hover effects
    Use `boringSmooth` for simple state changes
 
 5. BUTTON INTERACTIONS:
    Use `.bouncingStyle()` modifier for press feedback
 
 6. SLIDERS/PROGRESS BARS:
    Use `sliderDragSpring` for drag feedback
 
 7. DROP ZONES:
    Use `dropZoneSpring` for drop targeting feedback
 
 8. CORNER RADIUS:
    Use `CornerRadiusInsets.opened` / `.closed` for state transitions
 
 ============================================================
*/
