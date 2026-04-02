import Combine
import SwiftUI
import AppKit

/// Advanced visual effects compositor for premium UI
class VisualEffectsCompositor {
    static let shared = VisualEffectsCompositor()
    
    private init() {}
    
    // MARK: - Blur Effects
    
    func createDynamicBlur(intensity: CGFloat = 0.8, tintColor: NSColor? = nil) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow
        
        if let tintColor = tintColor {
            let colorView = NSView()
            colorView.wantsLayer = true
            colorView.layer?.backgroundColor = tintColor.withAlphaComponent(0.2).cgColor
            view.addSubview(colorView)
            colorView.frame = view.bounds
            colorView.autoresizingMask = [.width, .height]
        }
        
        return view
    }
    
    // MARK: - Gradient Effects
    
    func createAnimatedGradient(colors: [Color], animated: Bool = true) -> some View {
        AnimatedGradientView(colors: colors, animated: animated)
    }
    
    struct AnimatedGradientView: View {
        let colors: [Color]
        let animated: Bool
        
        @State private var startPoint: UnitPoint = .topLeading
        @State private var endPoint: UnitPoint = .bottomTrailing
        
        var body: some View {
            LinearGradient(
                colors: colors,
                startPoint: startPoint,
                endPoint: endPoint
            )
            .onAppear {
                if animated {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        startPoint = .bottomLeading
                        endPoint = .topTrailing
                    }
                }
            }
        }
    }
    
    // MARK: - Glow Effects
    
    func createGlowEffect(color: Color, radius: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(0.6),
                            color.opacity(0.3),
                            color.opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: radius
                    )
                )
                .blur(radius: radius / 2)
        }
    }
    
    // MARK: - Particle Effects
    
    func createParticleSystem(count: Int = 20) -> some View {
        ParticleSystemView(particleCount: count)
    }
    
    struct ParticleSystemView: View {
        let particleCount: Int
        @State private var particles: [Particle] = []
        
        struct Particle: Identifiable {
            let id = UUID()
            var x: CGFloat
            var y: CGFloat
            var size: CGFloat
            var opacity: Double
            var velocity: CGVector
        }
        
        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    ForEach(particles) { particle in
                        Circle()
                            .fill(Color.white)
                            .frame(width: particle.size, height: particle.size)
                            .opacity(particle.opacity)
                            .position(x: particle.x, y: particle.y)
                            .blur(radius: particle.size / 2)
                    }
                }
                .onAppear {
                    initializeParticles(in: geometry.size)
                    startAnimation()
                }
            }
        }
        
        private func initializeParticles(in size: CGSize) {
            particles = (0..<particleCount).map { _ in
                Particle(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height),
                    size: CGFloat.random(in: 2...6),
                    opacity: Double.random(in: 0.2...0.6),
                    velocity: CGVector(
                        dx: CGFloat.random(in: -0.5...0.5),
                        dy: CGFloat.random(in: -0.5...0.5)
                    )
                )
            }
        }
        
        private func startAnimation() {
            Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
                updateParticles()
            }
        }
        
        private func updateParticles() {
            for i in 0..<particles.count {
                particles[i].x += particles[i].velocity.dx
                particles[i].y += particles[i].velocity.dy
                
                // Wrap around edges
                if particles[i].x < 0 { particles[i].x = 300 }
                if particles[i].x > 300 { particles[i].x = 0 }
                if particles[i].y < 0 { particles[i].y = 200 }
                if particles[i].y > 200 { particles[i].y = 0 }
            }
        }
    }
    
    // MARK: - Morphing Shapes
    
    func createMorphingShape() -> some View {
        MorphingShapeView()
    }
    
    struct MorphingShapeView: View {
        @State private var phase: CGFloat = 0
        
        var body: some View {
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                let path = createMorphedPath(in: rect, phase: phase)
                
                context.fill(
                    Path(path.cgPath),
                    with: .linearGradient(
                        Gradient(colors: [.blue, .purple]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: size.width, y: size.height)
                    )
                )
            }
            .onAppear {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    phase = .pi * 2
                }
            }
        }
        
        private func createMorphedPath(in rect: CGRect, phase: CGFloat) -> NSBezierPath {
            let path = NSBezierPath()
            let centerX = rect.midX
            let centerY = rect.midY
            let radius = min(rect.width, rect.height) / 2
            
            let points = 8
            for i in 0...points {
                let angle = CGFloat(i) * (2 * .pi / CGFloat(points)) + phase
                let variation = sin(angle * 3 + phase) * 10
                let r = radius + variation
                let x = centerX + cos(angle) * r
                let y = centerY + sin(angle) * r
                
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.line(to: CGPoint(x: x, y: y))
                }
            }
            
            path.close()
            return path
        }
    }
    
    // MARK: - Glass Morphism
    
    func createGlassMorphism(tint: Color = .white, opacity: CGFloat = 0.1) -> some View {
        ZStack {
            Color.white.opacity(opacity)
            
            LinearGradient(
                colors: [
                    tint.opacity(0.2),
                    tint.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .blur(radius: 1)
    }
}

// MARK: - SwiftUI Wrappers

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        
        // CRITICAL: Ensure proper Retina scaling for crisp rendering
        view.wantsLayer = true
        if let layer = view.layer {
            layer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
            layer.shouldRasterize = false // Don't cache - keeps it sharp
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
        
        // Update scale on screen changes
        if let layer = nsView.layer {
            layer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        }
    }
}

// MARK: - View Extensions

extension View {
    func glassMorphism(tint: Color = .white, opacity: CGFloat = 0.1) -> some View {
        self.background(
            VisualEffectsCompositor.shared.createGlassMorphism(tint: tint, opacity: opacity)
        )
    }
    
    func glowEffect(color: Color = .accentColor, radius: CGFloat = 20) -> some View {
        self.background(
            VisualEffectsCompositor.shared.createGlowEffect(color: color, radius: radius)
        )
    }
}
