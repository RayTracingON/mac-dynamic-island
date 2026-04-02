import Foundation
import AppKit
import Combine

/// Detector for fullscreen media playback
class FullscreenMediaDetection: ObservableObject {
    static let shared = FullscreenMediaDetection()
    
    @Published var isFullscreenMediaActive = false
    @Published var activeApplication: NSRunningApplication?
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Known media applications
    private let mediaApps = [
        "com.apple.QuickTimePlayerX",
        "com.apple.TV",
        "com.google.Chrome",
        "org.mozilla.firefox",
        "com.apple.Safari",
        "com.spotify.client",
        "com.netflix.Netflix",
        "com.apple.Music"
    ]
    
    private init() {}
    
    deinit {
        stop()
    }
    
    // MARK: - Control
    
    func start() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkFullscreenMedia()
        }
        
        // Initial check
        checkFullscreenMedia()
        
        // Monitor application activation
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .sink { [weak self] _ in
                self?.checkFullscreenMedia()
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        cancellables.removeAll()
    }
    
    // MARK: - Detection
    
    private func checkFullscreenMedia() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            updateState(isActive: false, app: nil)
            return
        }
        
        // Check if it's a known media app
        guard let bundleID = frontApp.bundleIdentifier,
              mediaApps.contains(bundleID) else {
            updateState(isActive: false, app: nil)
            return
        }
        
        // Check for fullscreen windows
        let isFullscreen = isApplicationInFullscreen(frontApp)
        updateState(isActive: isFullscreen, app: isFullscreen ? frontApp : nil)
    }
    
    private func isApplicationInFullscreen(_ app: NSRunningApplication) -> Bool {
        // Get windows for the application
        guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        
        guard let mainScreen = NSScreen.main else {
            return false
        }
        
        let screenFrame = mainScreen.frame
        let pid = app.processIdentifier
        
        for window in windows {
            guard let windowPID = window[kCGWindowOwnerPID as String] as? Int32,
                  windowPID == pid,
                  let bounds = window[kCGWindowBounds as String] as? [String: CGFloat] else {
                continue
            }
            
            let windowFrame = CGRect(
                x: bounds["X"] ?? 0,
                y: bounds["Y"] ?? 0,
                width: bounds["Width"] ?? 0,
                height: bounds["Height"] ?? 0
            )
            
            // Check if window covers the entire screen
            if windowFrame.width >= screenFrame.width * 0.95 &&
               windowFrame.height >= screenFrame.height * 0.95 {
                return true
            }
        }
        
        return false
    }
    
    private func updateState(isActive: Bool, app: NSRunningApplication?) {
        DispatchQueue.main.async { [weak self] in
            self?.isFullscreenMediaActive = isActive
            self?.activeApplication = app
        }
    }
    
    // MARK: - Info
    
    var shouldHideNotch: Bool {
        return isFullscreenMediaActive
    }
    
    var activeAppName: String? {
        return activeApplication?.localizedName
    }
}
