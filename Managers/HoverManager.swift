import Foundation
import AppKit
import os.log

final class HoverManager {
    private weak var appState: AppState?
    private weak var overlayController: OverlayWindowController?
    
    private var monitor: Any?
    private var hoverTimer: Timer?
    private var lastHoverTime: Date?
    private let debounceInterval: TimeInterval = 0.3
    private let cooldownInterval: TimeInterval = 1.0
    
    private var isMonitoring = false
    
    init(appState: AppState, overlayController: OverlayWindowController) {
        self.appState = appState
        self.overlayController = overlayController
    }
    
    func start() {
        guard !isMonitoring else { return }
        guard let appState = appState else { return }
        guard appState.settings.hoverToOpen else {
            AppLogger.logError(NSError(domain: "HoverManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Hover disabled in settings"]), context: "HoverManager.start")
            return
        }
        
        isMonitoring = true
        
        // Register global mouse move monitor
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            self?.handleMouseMove()
        }
        AppLogger.logHoverDetected()
    }
    
    func stop() {
        guard isMonitoring else { return }
        isMonitoring = false
        
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        
        hoverTimer?.invalidate()
        hoverTimer = nil
    }
    
    private func handleMouseMove() {
        guard let appState = appState, appState.settings.hoverToOpen else { return }
        guard overlayController != nil else { return }
        
        // Debounce: only check position every N ms
        hoverTimer?.invalidate()
        hoverTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            self?.checkHoverPosition()
        }
    }
    
    private func checkHoverPosition() {
        guard let appState = appState, appState.settings.hoverToOpen else { return }
        
        // Removed direct access to `overlayController.window?.frame`
        // We assume the overlay is top-center for hover check purposes,
        // or we need to expose a safe way to get the frame if strictly necessary.
        // Given the comment "Hover MUST NOT expand", logging is the primary goal here.
        // We can approximate the position if needed, or skip the check if window access is restricted.
        
        // For now, we will use a safe fallback logic:
        // If we can't check the window frame, we can't reliably detect hover.
        // However, since hover is disabled for expansion anyway, we can just skip this check
        // or implement a safer way later if critical.
        
        let mouseLocation = NSEvent.mouseLocation
        
        // Fallback: Check top center of main screen
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let compactWidth: CGFloat = 185
        let compactHeight: CGFloat = 32
        
        let centerX = screenFrame.midX
        let topY = screenFrame.maxY
        
        // Approximate 200x50 detection zone at top center
        let hoverZone = CGRect(
            x: centerX - compactWidth/2 - 50,
            y: topY - compactHeight - 30,
            width: compactWidth + 100,
            height: compactHeight + 60
        )
        
        if hoverZone.contains(mouseLocation) {
             // Check cooldown to avoid rapid toggling
            let now = Date()
            if let lastTime = lastHoverTime, now.timeIntervalSince(lastTime) < cooldownInterval {
                return
            }
            
            lastHoverTime = now
            Log.hoverDetected()
            AppLogger.logHoverDetected()
            
            // Note: No expansion logic triggered here, as per design.
        }
    }
    
    // Unused helper removed as logic moved inline
    // private func isMouseNearWindow(...)
    
    deinit {
        stop()
    }
}
