import SwiftUI
import AppKit

/// SwiftUI wrapper for Lottie animations (placeholder if Lottie not installed)
struct LottieView: NSViewRepresentable {
    let animationName: String
    var loopMode: LottieLoopMode = .loop
    var contentMode: ContentMode = .scaleAspectFit
    var isPlaying: Bool = true
    
    func makeNSView(context: Context) -> LottieNSView {
        let view = LottieNSView()
        view.animationName = animationName
        view.loopMode = loopMode
        view.contentMode = contentMode
        
        if isPlaying {
            view.play()
        }
        
        return view
    }
    
    func updateNSView(_ nsView: LottieNSView, context: Context) {
        if isPlaying && !nsView.isAnimating {
            nsView.play()
        } else if !isPlaying && nsView.isAnimating {
            nsView.pause()
        }
    }
}

// MARK: - Native Implementation

class LottieNSView: NSView {
    var animationName: String = ""
    var loopMode: LottieLoopMode = .loop
    var contentMode: ContentMode = .scaleAspectFit
    var isAnimating = false
    
    private var displayLink: CVDisplayLink?
    private var animationProgress: CGFloat = 0.0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func play() {
        isAnimating = true
        startDisplayLink()
    }
    
    func pause() {
        isAnimating = false
        stopDisplayLink()
    }
    
    func stop() {
        isAnimating = false
        animationProgress = 0.0
        stopDisplayLink()
        needsDisplay = true
    }
    
    private func startDisplayLink() {
        guard displayLink == nil else { return }
        
        // Placeholder: In real implementation, would use CVDisplayLink
        // For now, using Timer as fallback
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isAnimating else {
                timer.invalidate()
                return
            }
            
            self.animationProgress += 0.01
            if self.animationProgress >= 1.0 {
                switch self.loopMode {
                case .playOnce:
                    self.animationProgress = 1.0
                    self.pause()
                case .loop:
                    self.animationProgress = 0.0
                case .autoReverse:
                    self.animationProgress = 0.0
                }
            }
            
            self.needsDisplay = true
        }
    }
    
    private func stopDisplayLink() {
        displayLink = nil
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Placeholder drawing - would be replaced with actual Lottie rendering
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        context.setFillColor(NSColor.systemBlue.withAlphaComponent(0.1).cgColor)
        context.fill(bounds)
        
        let text = "Lottie: \(animationName)" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attributes)
    }
}

enum LottieLoopMode {
    case playOnce
    case loop
    case autoReverse
}

enum ContentMode {
    case scaleToFill
    case scaleAspectFit
    case scaleAspectFill
}
