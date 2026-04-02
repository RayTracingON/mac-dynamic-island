import Combine
import SwiftUI

/// Micro-interaction effects for enhanced UX
struct MicroInteractions {
    
    // MARK: - Hover Effects
    
    struct HoverScaleEffect: ViewModifier {
        @State private var isHovered = false
        let scale: CGFloat
        let duration: TimeInterval
        
        init(scale: CGFloat = 1.05, duration: TimeInterval = 0.2) {
            self.scale = scale
            self.duration = duration
        }
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(isHovered ? scale : 1.0)
                .animation(.spring(response: duration, dampingFraction: 0.6), value: isHovered)
                .onHover { hovering in
                    isHovered = hovering
                    if hovering {
                        GestureHandler.shared.performHaptic(.generic)
                    }
                }
        }
    }
    
    struct HoverGlowEffect: ViewModifier {
        @State private var isHovered = false
        let color: Color
        let radius: CGFloat
        
        init(color: Color = .accentColor, radius: CGFloat = 8) {
            self.color = color
            self.radius = radius
        }
        
        func body(content: Content) -> some View {
            content
                .shadow(
                    color: isHovered ? color.opacity(0.6) : .clear,
                    radius: isHovered ? radius : 0
                )
                .animation(.easeInOut(duration: 0.25), value: isHovered)
                .onHover { hovering in
                    isHovered = hovering
                }
        }
    }
    
    // MARK: - Press Effects
    
    struct PressScaleEffect: ViewModifier {
        @State private var isPressed = false
        let scale: CGFloat
        
        init(scale: CGFloat = 0.95) {
            self.scale = scale
        }
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(isPressed ? scale : 1.0)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPressed {
                                withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                                    isPressed = true
                                }
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                isPressed = false
                            }
                        }
                )
        }
    }
    
    struct PressFlashEffect: ViewModifier {
        @State private var isPressed = false
        
        func body(content: Content) -> some View {
            content
                .brightness(isPressed ? 0.2 : 0)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPressed {
                                withAnimation(.easeOut(duration: 0.1)) {
                                    isPressed = true
                                }
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.easeIn(duration: 0.15)) {
                                isPressed = false
                            }
                        }
                )
        }
    }
    
    // MARK: - Loading Effects
    
    struct ShimmerEffect: ViewModifier {
        @State private var phase: CGFloat = 0
        let isActive: Bool
        
        func body(content: Content) -> some View {
            content
                .overlay(
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(isActive ? 0.3 : 0),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: phase)
                    .mask(content)
                )
                .onAppear {
                    if isActive {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            phase = 300
                        }
                    }
                }
        }
    }
    
    struct PulseEffect: ViewModifier {
        @State private var scale: CGFloat = 1.0
        let isActive: Bool
        let minScale: CGFloat
        let maxScale: CGFloat
        let duration: TimeInterval
        
        init(isActive: Bool, minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: TimeInterval = 0.8) {
            self.isActive = isActive
            self.minScale = minScale
            self.maxScale = maxScale
            self.duration = duration
        }
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(scale)
                .onAppear {
                    if isActive {
                        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                            scale = maxScale
                        }
                    }
                }
                .onChange(of: isActive) { _, active in
                    if active {
                        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                            scale = maxScale
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.3)) {
                            scale = 1.0
                        }
                    }
                }
        }
    }
    
    // MARK: - Attention Effects
    
    struct BounceAttention: ViewModifier {
        @State private var offset: CGFloat = 0
        let trigger: Int
        
        func body(content: Content) -> some View {
            content
                .offset(y: offset)
                .onChange(of: trigger) { _, _ in
                    performBounce()
                }
        }
        
        private func performBounce() {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                offset = -10
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    offset = 0
                }
            }
        }
    }
    
    struct WiggleEffect: ViewModifier {
        @State private var angle: Double = 0
        let trigger: Int
        
        func body(content: Content) -> some View {
            content
                .rotationEffect(.degrees(angle))
                .onChange(of: trigger) { _, _ in
                    performWiggle()
                }
        }
        
        private func performWiggle() {
            let sequence = [5.0, -5.0, 4.0, -4.0, 3.0, -3.0, 0.0]
            
            for (index, degree) in sequence.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) {
                    withAnimation(.linear(duration: 0.08)) {
                        angle = degree
                    }
                }
            }
        }
    }
    
    // MARK: - Reveal Effects
    
    struct SlideInEffect: ViewModifier {
        let isVisible: Bool
        let edge: Edge
        let distance: CGFloat
        
        init(isVisible: Bool, from edge: Edge = .leading, distance: CGFloat = 100) {
            self.isVisible = isVisible
            self.edge = edge
            self.distance = distance
        }
        
        func body(content: Content) -> some View {
            content
                .offset(
                    x: isVisible ? 0 : (edge == .leading ? -distance : (edge == .trailing ? distance : 0)),
                    y: isVisible ? 0 : (edge == .top ? -distance : (edge == .bottom ? distance : 0))
                )
                .opacity(isVisible ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isVisible)
        }
    }
    
    struct ScaleRevealEffect: ViewModifier {
        let isVisible: Bool
        let scale: CGFloat
        
        init(isVisible: Bool, fromScale scale: CGFloat = 0.3) {
            self.isVisible = isVisible
            self.scale = scale
        }
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(isVisible ? 1.0 : scale)
                .opacity(isVisible ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
        }
    }
}

// MARK: - View Extensions

extension View {
    func hoverScale(scale: CGFloat = 1.05, duration: TimeInterval = 0.2) -> some View {
        modifier(MicroInteractions.HoverScaleEffect(scale: scale, duration: duration))
    }
    
    func hoverGlow(color: Color = .accentColor, radius: CGFloat = 8) -> some View {
        modifier(MicroInteractions.HoverGlowEffect(color: color, radius: radius))
    }
    
    func pressScale(scale: CGFloat = 0.95) -> some View {
        modifier(MicroInteractions.PressScaleEffect(scale: scale))
    }
    
    func pressFlash() -> some View {
        modifier(MicroInteractions.PressFlashEffect())
    }
    
    func shimmer(isActive: Bool = true) -> some View {
        modifier(MicroInteractions.ShimmerEffect(isActive: isActive))
    }
    
    func pulseAnimation(
        isActive: Bool,
        minScale: CGFloat = 0.95,
        maxScale: CGFloat = 1.05,
        duration: TimeInterval = 0.8
    ) -> some View {
        modifier(MicroInteractions.PulseEffect(
            isActive: isActive,
            minScale: minScale,
            maxScale: maxScale,
            duration: duration
        ))
    }
    
    func bounceAttention(trigger: Int) -> some View {
        modifier(MicroInteractions.BounceAttention(trigger: trigger))
    }
    
    func wiggle(trigger: Int) -> some View {
        modifier(MicroInteractions.WiggleEffect(trigger: trigger))
    }
    
    func slideIn(isVisible: Bool, from edge: Edge = .leading, distance: CGFloat = 100) -> some View {
        modifier(MicroInteractions.SlideInEffect(isVisible: isVisible, from: edge, distance: distance))
    }
    
    func scaleReveal(isVisible: Bool, fromScale scale: CGFloat = 0.3) -> some View {
        modifier(MicroInteractions.ScaleRevealEffect(isVisible: isVisible, fromScale: scale))
    }
}
