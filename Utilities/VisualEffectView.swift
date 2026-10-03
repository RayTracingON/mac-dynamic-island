import SwiftUI
import AppKit

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
