import SwiftUI

/// Animated hello/welcome view
struct HelloAnimation: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = 0.0
    
    let text: String
    let duration: Double
    
    init(text: String = "Hello", duration: Double = 1.5) {
        self.text = text
        self.duration = duration
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated emoji or icon
            Text("👋")
                .font(.system(size: 60))
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
            
            // Animated text
            Text(text)
                .font(.title)
                .fontWeight(.bold)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: duration, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                rotation = 15.0
            }
        }
    }
}

/// Breathing animation effect
struct BreathingAnimation: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.8
    
    let color: Color
    let duration: Double
    
    init(color: Color = .accentColor, duration: Double = 2.0) {
        self.color = color
        self.duration = duration
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    scale = 1.3
                    opacity = 0.3
                }
            }
    }
}

/// Pulse animation effect
struct PulseAnimation: View {
    @State private var scale: CGFloat = 1.0
    
    let content: AnyView
    let duration: Double
    
    init<Content: View>(duration: Double = 1.0, @ViewBuilder content: () -> Content) {
        self.duration = duration
        self.content = AnyView(content())
    }
    
    var body: some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    scale = 1.1
                }
            }
    }
}

/// Shimmer loading effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

#Preview {
    VStack(spacing: 40) {
        HelloAnimation()
        
        BreathingAnimation()
            .frame(width: 100, height: 100)
        
        PulseAnimation {
        Text("Pulse Me")
                .font(Font.title)
        }
        
        Text("Shimmer Text")
            .font(Font.title)
            .shimmer()
    }
    .frame(width: 400, height: 600)
}
