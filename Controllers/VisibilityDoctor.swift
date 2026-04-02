#if DEBUG
import Cocoa
import SwiftUI

// MARK: - VisibilityDoctor
/// Deterministic on-screen visibility probe for debugging overlay issues.
/// Provides three test channels: NSWindow, NSPanel, and SwiftUI-hosted panel.
/// All methods are @objc for menu wiring.

final class VisibilityDoctor: NSObject {
    
    static let shared = VisibilityDoctor()
    
    // MARK: - Strong References (CRITICAL - must survive app lifetime)
    private var testWindow: NSWindow?
    private var testPanel: NSPanel?
    private var dynamicIslandPanel: NSPanel?
    private var hostingView: NSHostingView<DiagnosticView>?
    
    // Diagnostics state
    private(set) var showCount: Int = 0
    private(set) var lastAction: String = "(none)"
    private(set) var lastFrame: NSRect = .zero
    
    private let probeWidth: CGFloat = 400
    private let probeHeight: CGFloat = 200
    private let islandWidth: CGFloat = 380
    private let islandHeight: CGFloat = 50
    
    private override init() {
        super.init()
        print("🩺 [VisibilityDoctor] Singleton initialized")
    }
    
    // MARK: - Screen Detection
    
    private func primaryScreen() -> NSScreen {
        return NSScreen.main ?? NSScreen.screens.first!
    }
    
    private func topCenterFrame(width: CGFloat, height: CGFloat, margin: CGFloat = 12) -> NSRect {
        let screen = primaryScreen()
        let visibleFrame = screen.visibleFrame
        
        var x = visibleFrame.midX - (width / 2)
        var y = visibleFrame.maxY - height - margin
        
        // Clamp to visible frame
        x = max(visibleFrame.minX, min(x, visibleFrame.maxX - width))
        y = max(visibleFrame.minY, min(y, visibleFrame.maxY - height))
        
        return NSRect(x: x, y: y, width: width, height: height)
    }
    
    private func screenCenterFrame(width: CGFloat, height: CGFloat) -> NSRect {
        let screen = primaryScreen()
        let visibleFrame = screen.visibleFrame
        
        let x = visibleFrame.midX - (width / 2)
        let y = visibleFrame.midY - (height / 2)
        
        return NSRect(x: x, y: y, width: width, height: height)
    }
    
    // MARK: - A) Test Window (Normal NSWindow)
    
    @objc func showTestWindow() {
        showCount += 1
        lastAction = "showTestWindow"
        print("")
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║ 🩺 [VisibilityDoctor] showTestWindow() #\(showCount)                ║")
        print("╚══════════════════════════════════════════════════════════════╝")
        
        // Ensure main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.showTestWindow() }
            return
        }
        
        // Create if needed
        if testWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: probeWidth, height: probeHeight),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "🩺 Test Window (NSWindow)"
            window.backgroundColor = NSColor.systemGreen.withAlphaComponent(0.9)
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isReleasedWhenClosed = false
            window.hidesOnDeactivate = false
            
            // Simple content
            let label = NSTextField(labelWithString: "✅ NSWindow VISIBLE\n\nIf you see this, normal windows work.")
            label.font = NSFont.boldSystemFont(ofSize: 16)
            label.alignment = .center
            label.frame = NSRect(x: 20, y: 60, width: probeWidth - 40, height: 80)
            window.contentView?.addSubview(label)
            
            testWindow = window
            print("🩺 [VisibilityDoctor] NSWindow created")
        }
        
        guard let window = testWindow else { return }
        
        // Position at center
        let frame = screenCenterFrame(width: probeWidth, height: probeHeight)
        window.setFrame(frame, display: true)
        lastFrame = frame
        
        // Force to front
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        
        print("🩺 [VisibilityDoctor] NSWindow shown: visible=\(window.isVisible) frame=\(window.frame)")
    }
    
    // MARK: - B) Test Panel (Red Semi-Transparent NSPanel)
    
    @objc func showTestPanel() {
        showCount += 1
        lastAction = "showTestPanel"
        print("")
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║ 🩺 [VisibilityDoctor] showTestPanel() #\(showCount)                 ║")
        print("╚══════════════════════════════════════════════════════════════╝")
        
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.showTestPanel() }
            return
        }
        
        if testPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: probeWidth, height: probeHeight),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            // CRITICAL panel configuration for overlay-style visibility
            panel.isOpaque = false
            panel.backgroundColor = NSColor.red.withAlphaComponent(0.7)  // BRIGHT RED
            panel.hasShadow = true
            panel.level = .statusBar  // Level 25
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
            panel.isMovableByWindowBackground = true
            panel.ignoresMouseEvents = false
            panel.hidesOnDeactivate = false  // CRITICAL
            panel.isReleasedWhenClosed = false  // CRITICAL
            panel.alphaValue = 1.0
            panel.animationBehavior = .none
            
            // Simple label
            let label = NSTextField(labelWithString: "🔴 NSPanel VISIBLE\n\nLevel: statusBar (25)\nStyle: borderless, nonactivatingPanel")
            label.font = NSFont.boldSystemFont(ofSize: 14)
            label.textColor = .white
            label.backgroundColor = .clear
            label.isBezeled = false
            label.isEditable = false
            label.alignment = .center
            label.frame = NSRect(x: 20, y: 50, width: probeWidth - 40, height: 100)
            panel.contentView?.addSubview(label)
            
            testPanel = panel
            print("🩺 [VisibilityDoctor] NSPanel created")
        }
        
        guard let panel = testPanel else { return }
        
        // Position at top-center
        let frame = topCenterFrame(width: probeWidth, height: probeHeight)
        panel.setFrame(frame, display: true)
        lastFrame = frame
        
        // Force to front
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        
        print("🩺 [VisibilityDoctor] NSPanel shown: visible=\(panel.isVisible) frame=\(panel.frame) level=\(panel.level.rawValue)")
    }
    
    // MARK: - C) Dynamic Island SwiftUI Panel
    
    @objc func showDynamicIsland() {
        showCount += 1
        lastAction = "showDynamicIsland"
        print("")
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║ 🩺 [VisibilityDoctor] showDynamicIsland() #\(showCount)             ║")
        print("╚══════════════════════════════════════════════════════════════╝")
        
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.showDynamicIsland() }
            return
        }
        
        if dynamicIslandPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: islandWidth, height: islandHeight),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            // Dynamic Island style configuration
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.level = .statusBar
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
            panel.isMovableByWindowBackground = true
            panel.ignoresMouseEvents = false
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
            panel.alphaValue = 1.0
            
            // SwiftUI content
            let content = DiagnosticView(doctor: self)
            let hosting = NSHostingView(rootView: content)
            hosting.frame = NSRect(x: 0, y: 0, width: islandWidth, height: islandHeight)
            hosting.autoresizingMask = [.width, .height]
            panel.contentView = hosting
            
            hostingView = hosting
            dynamicIslandPanel = panel
            print("🩺 [VisibilityDoctor] Dynamic Island panel created")
        }
        
        guard let panel = dynamicIslandPanel else { return }
        
        // Position at top-center (notch position)
        let frame = topCenterFrame(width: islandWidth, height: islandHeight, margin: 8)
        panel.setFrame(frame, display: true)
        lastFrame = frame
        
        // Update SwiftUI view
        hostingView?.rootView = DiagnosticView(doctor: self)
        
        // Force to front
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        
        print("🩺 [VisibilityDoctor] Dynamic Island shown: visible=\(panel.isVisible) frame=\(panel.frame) level=\(panel.level.rawValue)")
    }
    
    // MARK: - Hide All
    
    @objc func hideAll() {
        lastAction = "hideAll"
        print("🩺 [VisibilityDoctor] hideAll() called")
        
        testWindow?.orderOut(nil)
        testPanel?.orderOut(nil)
        dynamicIslandPanel?.orderOut(nil)
        
        print("🩺 [VisibilityDoctor] All windows hidden")
    }
    
    // MARK: - Center All
    
    @objc func centerAll() {
        lastAction = "centerAll"
        print("🩺 [VisibilityDoctor] centerAll() called")
        
        if let window = testWindow, window.isVisible {
            let frame = screenCenterFrame(width: probeWidth, height: probeHeight)
            window.setFrame(frame, display: true)
            window.orderFrontRegardless()
        }
        
        if let panel = testPanel, panel.isVisible {
            let frame = topCenterFrame(width: probeWidth, height: probeHeight)
            panel.setFrame(frame, display: true)
            panel.orderFrontRegardless()
        }
        
        if let panel = dynamicIslandPanel, panel.isVisible {
            let frame = topCenterFrame(width: islandWidth, height: islandHeight, margin: 8)
            panel.setFrame(frame, display: true)
            panel.orderFrontRegardless()
        }
        
        print("🩺 [VisibilityDoctor] All visible windows centered")
    }
    
    // MARK: - Dump State
    
    @objc func dumpState() {
        lastAction = "dumpState"
        print("")
        print("╔══════════════════════════════════════════════════════════════╗")
        print("║ 🩺 [VisibilityDoctor] DUMP STATE                              ║")
        print("╠══════════════════════════════════════════════════════════════╣")
        print("║ showCount: \(showCount)")
        print("║ lastAction: \(lastAction)")
        print("║ lastFrame: \(lastFrame)")
        print("╠══════════════════════════════════════════════════════════════╣")
        print("║ NSApp.activationPolicy: \(activationPolicyString())")
        print("║ NSApp.isActive: \(NSApp.isActive)")
        print("║ NSApp.isHidden: \(NSApp.isHidden)")
        print("╠══════════════════════════════════════════════════════════════╣")
        
        let screen = primaryScreen()
        print("║ Primary screen: \(screen.localizedName)")
        print("║ Screen frame: \(screen.frame)")
        print("║ Screen visibleFrame: \(screen.visibleFrame)")
        print("╠══════════════════════════════════════════════════════════════╣")
        
        if let w = testWindow {
            print("║ TEST WINDOW:")
            print("║   isVisible: \(w.isVisible)")
            print("║   frame: \(w.frame)")
            print("║   level: \(w.level.rawValue)")
        } else {
            print("║ TEST WINDOW: nil")
        }
        
        if let p = testPanel {
            print("║ TEST PANEL:")
            print("║   isVisible: \(p.isVisible)")
            print("║   frame: \(p.frame)")
            print("║   level: \(p.level.rawValue)")
            print("║   hidesOnDeactivate: \(p.hidesOnDeactivate)")
        } else {
            print("║ TEST PANEL: nil")
        }
        
        if let p = dynamicIslandPanel {
            print("║ DYNAMIC ISLAND PANEL:")
            print("║   isVisible: \(p.isVisible)")
            print("║   frame: \(p.frame)")
            print("║   level: \(p.level.rawValue)")
            print("║   hidesOnDeactivate: \(p.hidesOnDeactivate)")
        } else {
            print("║ DYNAMIC ISLAND PANEL: nil")
        }
        
        print("╠══════════════════════════════════════════════════════════════╣")
        print("║ ALL NSApp.windows (\(NSApp.windows.count) total):")
        for (i, w) in NSApp.windows.enumerated() {
            let typeStr = String(describing: type(of: w))
            print("║   [\(i)] \(typeStr.prefix(30))")
            print("║       visible=\(w.isVisible) level=\(w.level.rawValue) frame=\(formatRect(w.frame))")
        }
        print("╚══════════════════════════════════════════════════════════════╝")
        print("")
    }
    
    // MARK: - Helpers
    
    private func activationPolicyString() -> String {
        switch NSApp.activationPolicy() {
        case .regular: return ".regular (Dock icon)"
        case .accessory: return ".accessory (menu bar only)"
        case .prohibited: return ".prohibited (background)"
        @unknown default: return "unknown"
        }
    }
    
    private func formatRect(_ rect: NSRect) -> String {
        return String(format: "(%.0f,%.0f %.0fx%.0f)", rect.origin.x, rect.origin.y, rect.width, rect.height)
    }
}

// MARK: - Diagnostic SwiftUI View

struct DiagnosticView: View {
    let doctor: VisibilityDoctor
    
    var body: some View {
        HStack(spacing: 12) {
            // Green indicator
            Circle()
                .fill(Color.green)
                .frame(width: 14, height: 14)
                .shadow(color: .green, radius: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("🩺 Dynamic Island DEBUG")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Show #\(doctor.showCount) | \(doctor.lastAction)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Sparkle icon
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundColor(.yellow)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color.black.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(Color.green.opacity(0.8), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
    }
}

#endif // DEBUG
