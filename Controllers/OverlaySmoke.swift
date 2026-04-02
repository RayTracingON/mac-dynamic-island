#if DEBUG
import Cocoa
import SwiftUI

// MARK: - Debug Overlay Manager (Singleton)

/// Robust debug overlay manager with panel + window fallback channels.
/// Guarantees visibility even in accessory/agent app modes.
final class OverlaySmoke {
    
    static let shared = OverlaySmoke()
    
    // MARK: - Strong References (CRITICAL - must survive app lifetime)
    private var panel: NSPanel?
    private var fallbackWindow: NSWindow?
    private var panelHostingView: NSHostingView<DebugOverlayView>?
    private var windowHostingView: NSHostingView<DebugOverlayView>?
    
    // Debug state for view
    private(set) var lastFrame: NSRect = .zero
    private(set) var lastScreen: String = "unknown"
    private(set) var lastVisibleFrame: NSRect = .zero
    private(set) var showCount: Int = 0
    
    private let overlayWidth: CGFloat = 500
    private let overlayHeight: CGFloat = 280
    
    private init() {
        print("🟡 [DebugOverlayManager] Singleton initialized on thread: \(Thread.isMainThread ? "main" : "background")")
    }
    
    // MARK: - Screen Detection (Mouse-Based)
    
    private func screenUnderMouse() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouseLocation) } ?? NSScreen.main ?? NSScreen.screens.first!
        return screen
    }
    
    // MARK: - Frame Calculation (Guaranteed On-Screen)
    
    private func computeFrame(on screen: NSScreen) -> NSRect {
        let visibleFrame = screen.visibleFrame
        
        // Top-center with 12pt margin, clamped to visible frame
        var x = visibleFrame.midX - (overlayWidth / 2)
        var y = visibleFrame.maxY - overlayHeight - 12
        
        // Clamp to visible frame
        x = max(visibleFrame.minX, min(x, visibleFrame.maxX - overlayWidth))
        y = max(visibleFrame.minY, min(y, visibleFrame.maxY - overlayHeight))
        
        return NSRect(x: x, y: y, width: overlayWidth, height: overlayHeight)
    }
    
    // MARK: - Forensic Logging
    
    private func logDiagnostics(tag: String) {
        print("")
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║ [\(tag)] FORENSIC DIAGNOSTICS                              ║")
        print("╠══════════════════════════════════════════════════════════════╣")
        print("║ NSApp.activationPolicy: \(activationPolicyString())")
        print("║ NSApp.isActive: \(NSApp.isActive)")
        print("║ NSApp.isRunning: \(NSApp.isRunning)")
        print("║ NSApp.isHidden: \(NSApp.isHidden)")
        print("╠══════════════════════════════════════════════════════════════╣")
        
        let screen = screenUnderMouse()
        print("║ Screen under mouse: \(screen.localizedName)")
        print("║ Screen frame: \(screen.frame)")
        print("║ Screen visibleFrame: \(screen.visibleFrame)")
        print("╠══════════════════════════════════════════════════════════════╣")
        
        if let p = panel {
            print("║ PANEL:")
            print("║   isVisible: \(p.isVisible)")
            print("║   frame: \(p.frame)")
            print("║   level: \(p.level.rawValue) (statusBar=25, popUpMenu=101)")
            print("║   alphaValue: \(p.alphaValue)")
            print("║   occlusionState: \(p.occlusionState)")
            print("║   isOnActiveSpace: \(p.isOnActiveSpace)")
            print("║   isKeyWindow: \(p.isKeyWindow)")
            print("║   contentView: \(String(describing: p.contentView))")
        } else {
            print("║ PANEL: nil")
        }
        
        print("╠══════════════════════════════════════════════════════════════╣")
        
        if let w = fallbackWindow {
            print("║ FALLBACK WINDOW:")
            print("║   isVisible: \(w.isVisible)")
            print("║   frame: \(w.frame)")
            print("║   level: \(w.level.rawValue)")
        } else {
            print("║ FALLBACK WINDOW: nil")
        }
        
        print("╠══════════════════════════════════════════════════════════════╣")
        print("║ ALL NSApp.windows:")
        for (i, w) in NSApp.windows.enumerated() {
            print("║   [\(i)] \(type(of: w)) visible=\(w.isVisible) frame=\(w.frame) level=\(w.level.rawValue)")
        }
        print("╚══════════════════════════════════════════════════════════════╝")
        print("")
    }
    
    private func activationPolicyString() -> String {
        switch NSApp.activationPolicy() {
        case .regular: return ".regular (Dock icon)"
        case .accessory: return ".accessory (menu bar only)"
        case .prohibited: return ".prohibited (background)"
        @unknown default: return "unknown"
        }
    }
    
    // MARK: - Panel Creation
    
    private func ensurePanel() {
        guard panel == nil else { return }
        
        print("🛠️ [DebugOverlayManager] Creating NSPanel...")
        
        let newPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: overlayWidth, height: overlayHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // CRITICAL configuration for visibility
        newPanel.isOpaque = false
        newPanel.backgroundColor = NSColor.red.withAlphaComponent(0.15) // DEBUG: Visible red tint
        newPanel.hasShadow = true
        newPanel.level = .statusBar // Level 25 - above most windows
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        newPanel.isMovableByWindowBackground = true
        newPanel.ignoresMouseEvents = false
        newPanel.hidesOnDeactivate = false
        newPanel.isReleasedWhenClosed = false // CRITICAL
        newPanel.alphaValue = 1.0
        newPanel.animationBehavior = .none
        
        // SwiftUI content
        let content = DebugOverlayView(manager: self)
        let hosting = NSHostingView(rootView: content)
        hosting.frame = NSRect(x: 0, y: 0, width: overlayWidth, height: overlayHeight)
        hosting.autoresizingMask = [.width, .height]
        
        newPanel.contentView = hosting
        
        // Store strong references
        self.panelHostingView = hosting
        self.panel = newPanel
        
        print("✅ [DebugOverlayManager] NSPanel created successfully")
    }
    
    // MARK: - Fallback Window Creation
    
    private func ensureFallbackWindow() {
        guard fallbackWindow == nil else { return }
        
        print("🛠️ [DebugOverlayManager] Creating fallback NSWindow...")
        
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: overlayWidth, height: overlayHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Same configuration as panel
        newWindow.isOpaque = false
        newWindow.backgroundColor = NSColor.blue.withAlphaComponent(0.15) // DEBUG: Blue tint for fallback
        newWindow.hasShadow = true
        newWindow.level = .floating // Try floating for fallback
        newWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newWindow.isMovableByWindowBackground = true
        newWindow.ignoresMouseEvents = false
        newWindow.isReleasedWhenClosed = false // CRITICAL
        newWindow.alphaValue = 1.0
        
        // SwiftUI content
        let content = DebugOverlayView(manager: self, isFallback: true)
        let hosting = NSHostingView(rootView: content)
        hosting.frame = NSRect(x: 0, y: 0, width: overlayWidth, height: overlayHeight)
        hosting.autoresizingMask = [.width, .height]
        
        newWindow.contentView = hosting
        
        // Store strong references
        self.windowHostingView = hosting
        self.fallbackWindow = newWindow
        
        print("✅ [DebugOverlayManager] Fallback NSWindow created successfully")
    }
    
    // MARK: - Force Activation
    
    private func forceActivation() {
        print("⚡ [DebugOverlayManager] Forcing app activation...")
        // NSApp.activate(ignoringOtherApps: true) - Deprecated in macOS 14
        NSRunningApplication.current.activate(options: [.activateAllWindows])
    }
    
    // MARK: - Public API: Show Panel
    
    func show() {
        showCount += 1
        print("")
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║ 🟢 [DebugOverlayManager] show() CALLED (count: \(showCount))   ║")
        print("╚══════════════════════════════════════════════════════════════╝")
        
        // Ensure main thread
        if !Thread.isMainThread {
            print("⚠️ [DebugOverlayManager] Not on main thread, dispatching...")
            DispatchQueue.main.async { self.show() }
            return
        }
        
        // Create panel if needed
        ensurePanel()
        
        guard let panel = panel else {
            print("❌ [DebugOverlayManager] FATAL: panel is nil after ensurePanel()")
            logDiagnostics(tag: "PANEL_NIL")
            return
        }
        
        // Get screen under mouse
        let screen = screenUnderMouse()
        lastScreen = screen.localizedName
        lastVisibleFrame = screen.visibleFrame
        
        // Compute frame
        let frame = computeFrame(on: screen)
        lastFrame = frame
        
        print("📺 [DebugOverlayManager] Target screen: \(screen.localizedName)")
        print("📐 [DebugOverlayManager] Computed frame: \(frame)")
        
        // Set frame
        panel.setFrame(frame, display: true)
        
        // Force activation
        forceActivation()
        
        // Force to front
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
        
        // Update SwiftUI view
        if let hosting = panelHostingView {
            hosting.rootView = DebugOverlayView(manager: self)
        }
        
        // Log diagnostics
        logDiagnostics(tag: "AFTER_SHOW_PANEL")
        
        print("🟢 [DebugOverlayManager] Panel show complete. isVisible=\(panel.isVisible)")
    }
    
    // MARK: - Public API: Show Fallback Window
    
    func showDebugWindow() {
        showCount += 1
        print("")
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║ 🔵 [DebugOverlayManager] showDebugWindow() CALLED           ║")
        print("╚══════════════════════════════════════════════════════════════╝")
        
        // Ensure main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { self.showDebugWindow() }
            return
        }
        
        // Create window if needed
        ensureFallbackWindow()
        
        guard let window = fallbackWindow else {
            print("❌ [DebugOverlayManager] FATAL: fallbackWindow is nil")
            return
        }
        
        // Get screen under mouse
        let screen = screenUnderMouse()
        lastScreen = screen.localizedName
        lastVisibleFrame = screen.visibleFrame
        
        // Compute frame
        let frame = computeFrame(on: screen)
        lastFrame = frame
        
        // Set frame
        window.setFrame(frame, display: true)
        
        // Force activation
        forceActivation()
        
        // Force to front
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        
        // Update SwiftUI view
        if let hosting = windowHostingView {
            hosting.rootView = DebugOverlayView(manager: self, isFallback: true)
        }
        
        // Log diagnostics
        logDiagnostics(tag: "AFTER_SHOW_WINDOW")
        
        print("🔵 [DebugOverlayManager] Fallback window show complete. isVisible=\(window.isVisible)")
    }
    
    // MARK: - Public API: Hide
    
    func hide() {
        print("🔴 [DebugOverlayManager] hide() called")
        panel?.orderOut(nil)
        fallbackWindow?.orderOut(nil)
        logDiagnostics(tag: "AFTER_HIDE")
    }
    
    // MARK: - Public API: Center
    
    func center() {
        print("🎯 [DebugOverlayManager] center() called")
        
        let screen = screenUnderMouse()
        let frame = computeFrame(on: screen)
        lastFrame = frame
        lastScreen = screen.localizedName
        lastVisibleFrame = screen.visibleFrame
        
        if let p = panel {
            p.setFrame(frame, display: true)
            p.orderFrontRegardless()
        }
        
        if let w = fallbackWindow {
            w.setFrame(frame, display: true)
            w.orderFrontRegardless()
        }
        
        // Update views
        if let hosting = panelHostingView {
            hosting.rootView = DebugOverlayView(manager: self)
        }
        if let hosting = windowHostingView {
            hosting.rootView = DebugOverlayView(manager: self, isFallback: true)
        }
        
        print("🎯 [DebugOverlayManager] Centered at \(frame)")
    }
    
    // MARK: - Public API: Move to Fixed Position
    
    func moveTo(x: CGFloat, y: CGFloat) {
        print("📍 [DebugOverlayManager] moveTo(\(x), \(y)) called")
        
        let frame = NSRect(x: x, y: y, width: overlayWidth, height: overlayHeight)
        lastFrame = frame
        
        if let p = panel {
            p.setFrame(frame, display: true)
            p.orderFrontRegardless()
        }
        
        if let w = fallbackWindow {
            w.setFrame(frame, display: true)
            w.orderFrontRegardless()
        }
        
        // Update views
        if let hosting = panelHostingView {
            hosting.rootView = DebugOverlayView(manager: self)
        }
        if let hosting = windowHostingView {
            hosting.rootView = DebugOverlayView(manager: self, isFallback: true)
        }
    }
    
    var isVisible: Bool {
        return (panel?.isVisible ?? false) || (fallbackWindow?.isVisible ?? false)
    }
    
    var panelIsVisible: Bool {
        return panel?.isVisible ?? false
    }
    
    var windowIsVisible: Bool {
        return fallbackWindow?.isVisible ?? false
    }
}

// MARK: - Debug Overlay SwiftUI View

struct DebugOverlayView: View {
    let manager: OverlaySmoke
    var isFallback: Bool = false
    
    var body: some View {
        VStack(spacing: 10) {
            // Big header
            Text(isFallback ? "🔵 DEBUG WINDOW VISIBLE" : "🔴 DEBUG PANEL VISIBLE")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.white)
            
            Text("OVERLAY IS WORKING!")
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.yellow)
            
            Divider()
                .background(Color.white)
            
            // Diagnostic info
            VStack(alignment: .leading, spacing: 4) {
                Text("Show count: \(manager.showCount)")
                Text("Frame: \(formatRect(manager.lastFrame))")
                Text("Screen: \(manager.lastScreen)")
                Text("VisibleFrame: \(formatRect(manager.lastVisibleFrame))")
                Text("ActivationPolicy: \(activationPolicyString())")
                Text("isActive: \(NSApp.isActive ? "YES" : "NO")")
            }
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundColor(.white)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(isFallback ? Color.blue.opacity(0.85) : Color.red.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isFallback ? Color.cyan : Color.yellow, lineWidth: 6)
        )
        .shadow(color: .black.opacity(0.5), radius: 20)
        .padding(8)
    }
    
    private func formatRect(_ rect: NSRect) -> String {
        return String(format: "(%.0f, %.0f) %.0fx%.0f", rect.origin.x, rect.origin.y, rect.width, rect.height)
    }
    
    private func activationPolicyString() -> String {
        switch NSApp.activationPolicy() {
        case .regular: return ".regular"
        case .accessory: return ".accessory"
        case .prohibited: return ".prohibited"
        @unknown default: return "unknown"
        }
    }
}
#endif // DEBUG
