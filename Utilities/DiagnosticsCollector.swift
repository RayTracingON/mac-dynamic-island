import Foundation
import AppKit

@MainActor
struct DiagnosticsCollector {
    static func generateReport() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        let macOSVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let screenCount = NSScreen.screens.count
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        let settings = AppSettings.shared
        let appState = AppState()  // Create temporary instance or pass via dependency
        let overlayState = getOverlayState()
        let windowInfo = getWindowInfo()
        let trayInfo = getTrayInfo(appState: appState)
        let recentLogs = getRecentLogs()
        
        let report = """
        === Mac灵动岛 Diagnostics Report ===
        Exported: \(timestamp)
        
        VERSION & BUILD
        App Version: \(appVersion)
        Build Number: \(buildNumber)
        macOS: \(macOSVersion)
        Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")
        
        SYSTEM
        Display Count: \(screenCount)
        Active Display: \(NSScreen.main?.localizedName ?? "unknown")
        
        SETTINGS
        Launch at Login: \(settings.launchAtLogin)
        Hover to Open: \(settings.hoverToOpen)
        Display Mode: \(settings.displayMode.rawValue)
        Panel Width: \(Int(settings.panelWidth))px
        Reduce Motion: \(settings.reduceMotion)
        
        OVERLAY STATE
        \(overlayState)
        
        TRAY
        \(trayInfo)
        
        WINDOW INFO
        \(windowInfo)
        
        RECENT LOGS (last 30 entries)
        \(recentLogs)
        
        === End Report ===
        """
        
        return report
    }
    
    private static func getOverlayState() -> String {
        if let mainWindow = NSApp.windows.first(where: { $0.level == .statusBar }) {
            let visible = mainWindow.isVisible
            let frame = mainWindow.frame
            return "Overlay: \(visible ? "visible" : "hidden")"
                + "\nPosition: x=\(Int(frame.origin.x)), y=\(Int(frame.origin.y))"
                + "\nSize: \(Int(frame.width))×\(Int(frame.height))"
        }
        return "Overlay: unknown"
    }
    
    private static func getWindowInfo() -> String {
        let windows = NSApp.windows.count
        return "Total Windows: \(windows)"
    }
    
    private static func getTrayInfo(appState: AppState) -> String {
        let count = appState.trayItems.count
        let items = appState.trayItems.prefix(5).map { $0.displayName }.joined(separator: ", ")
        let more = count > 5 ? " (+\(count - 5) more)" : ""
        return "Tray Items: \(count)\nSample: \(items.isEmpty ? "(empty)" : items)\(more)"
    }
    
    private static func getRecentLogs() -> String {
        let logs = logBuffer.getAll()
        let recent = logs.suffix(30).joined(separator: "\n")
        return recent.isEmpty ? "(no logs captured)" : recent
    }
}
