import SwiftUI

extension View {
    /// Add border with rounded corners
    func border(color: Color, width: CGFloat, cornerRadius: CGFloat) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color, lineWidth: width)
        )
    }
    
    /// Add conditional modifier - boring.notch 风格
    @ViewBuilder
    func conditionalModifier<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Add conditional modifier (legacy name for compatibility)
    @ViewBuilder
    func conditionally<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Add glow effect
    func glow(color: Color = .white, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
            .shadow(color: color, radius: radius / 3)
    }
    
    /// Add shimmer effect
    func shimmerEffect() -> some View {
        self.overlay(
            LinearGradient(
                colors: [.clear, .white.opacity(0.3), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    /// Make view circular
    func circularClip() -> some View {
        self.clipShape(Circle())
    }
    
    /// Add blur background
    func blurBackground(style: Material = .ultraThinMaterial) -> some View {
        self.background(style)
    }
    
    /// Add corner radius to specific corners
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    /// Hide view conditionally
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }
    
    // MARK: - Boring Notch Pan Gesture 手势支持
    
    /// 双指滑动手势 - 完美复刻 boring.notch 的丝滑交互
    /// - Parameters:
    ///   - direction: 手势方向 (.up 或 .down)
    ///   - action: 回调，传递滑动距离和手势阶段
    func panGesture(
        direction: PanGestureDirection,
        action: @escaping (CGFloat, NSEvent.Phase) -> Void
    ) -> some View {
        self.modifier(PanGestureModifier(direction: direction, onGesture: action))
    }
    
    /// Clipboard key router - handles keyboard navigation for clipboard hub
    func clipboardKeyRouter(hubStore: ClipboardHubStore, appState: AppState) -> some View {
        self // Placeholder: Implementation would listen to keyDown and update hubStore selection
    }
}

// MARK: - Pan Gesture Direction

enum PanGestureDirection {
    case up
    case down
    case left
    case right
}

// MARK: - Pan Gesture Modifier (Boring Notch 核心手势实现)

struct PanGestureModifier: ViewModifier {
    let direction: PanGestureDirection
    let onGesture: (CGFloat, NSEvent.Phase) -> Void
    
    @State private var accumulatedTranslation: CGFloat = 0
    @State private var monitor: Any?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                guard monitor == nil else { return }
                // Install local monitor for scroll events
                monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                    handleScrollEvent(event)
                    return event
                }
            }
            .onDisappear {
                if let monitor = monitor {
                    NSEvent.removeMonitor(monitor)
                    self.monitor = nil
                }
            }
    }
    
    private func handleScrollEvent(_ event: NSEvent) {
        // Only process if view is still alive
        guard monitor != nil else { return }
        
        // 仅处理双指触控板滑动 (非鼠标滚轮)
        // NSEvent.Phase is an OptionSet, use [] for no phase check
        guard event.momentumPhase == [] || event.phase != [] else {
            return
        }
        
        let deltaY = event.scrollingDeltaY
        let deltaX = event.scrollingDeltaX
        
        // 根据方向过滤
        switch direction {
        case .down:
            guard deltaY < 0 || event.phase == .ended else { return }
            accumulatedTranslation += abs(deltaY)
        case .up:
            guard deltaY > 0 || event.phase == .ended else { return }
            accumulatedTranslation += abs(deltaY)
        case .left:
            guard deltaX < 0 || event.phase == .ended else { return }
            accumulatedTranslation += abs(deltaX)
        case .right:
            guard deltaX > 0 || event.phase == .ended else { return }
            accumulatedTranslation += abs(deltaX)
        }
        
        // 回调
        onGesture(accumulatedTranslation, event.phase)
        
        // 手势结束时重置
        if event.phase == .ended || event.phase == .cancelled {
            accumulatedTranslation = 0
        }
    }
}

// MARK: - Helper Shapes

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = NSBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0..<elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            case .cubicCurveTo:
                // Handle cubic curves (same as curveTo)
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                // Handle quadratic curves
                path.addQuadCurve(to: points[1], control: points[0])
            @unknown default:
                break
            }
        }
        
        return path
    }
    
    convenience init(roundedRect rect: CGRect, byRoundingCorners corners: RectCorner, cornerRadii: CGSize) {
        self.init()
        
        let topLeft = rect.origin
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        
        if corners.contains(.topLeft) {
            move(to: CGPoint(x: topLeft.x + cornerRadii.width, y: topLeft.y))
        } else {
            move(to: topLeft)
        }
        
        if corners.contains(.topRight) {
            line(to: CGPoint(x: topRight.x - cornerRadii.width, y: topRight.y))
            appendArc(
                withCenter: CGPoint(x: topRight.x - cornerRadii.width, y: topRight.y + cornerRadii.height),
                radius: cornerRadii.width,
                startAngle: 270,
                endAngle: 0,
                clockwise: false
            )
        } else {
            line(to: topRight)
        }
        
        if corners.contains(.bottomRight) {
            line(to: CGPoint(x: bottomRight.x, y: bottomRight.y - cornerRadii.height))
            appendArc(
                withCenter: CGPoint(x: bottomRight.x - cornerRadii.width, y: bottomRight.y - cornerRadii.height),
                radius: cornerRadii.width,
                startAngle: 0,
                endAngle: 90,
                clockwise: false
            )
        } else {
            line(to: bottomRight)
        }
        
        if corners.contains(.bottomLeft) {
            line(to: CGPoint(x: bottomLeft.x + cornerRadii.width, y: bottomLeft.y))
            appendArc(
                withCenter: CGPoint(x: bottomLeft.x + cornerRadii.width, y: bottomLeft.y - cornerRadii.height),
                radius: cornerRadii.width,
                startAngle: 90,
                endAngle: 180,
                clockwise: false
            )
        } else {
            line(to: bottomLeft)
        }
        
        close()
    }
}

