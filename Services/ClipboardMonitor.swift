import Foundation
import AppKit
import OSLog

/// Lightweight clipboard monitor - 0.5s polling, no busy logging
final class ClipboardMonitor {
    
    private weak var store: ClipboardHistoryStore?
    private var pollingTimer: Timer?
    private var lastChangeCount: Int = 0
    private let logger = os.Logger(subsystem: "com.maclingdonggao.overlay", category: "clipboard_monitor")
    
    // MARK: - Lifecycle
    
    init(store: ClipboardHistoryStore) {
        self.store = store
        self.lastChangeCount = NSPasteboard.general.changeCount
    }
    
    func start() {
        // Initial state
        lastChangeCount = NSPasteboard.general.changeCount
        
        // Poll every 0.5 seconds (lightweight, no noticeable CPU)
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        
        #if DEBUG
        logger.debug("Started")
        #endif
    }
    
    func stop() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        
        #if DEBUG
        logger.debug("Stopped")
        #endif
    }
    
    // MARK: - Change Detection
    
    private func checkForChanges() {
        let currentChangeCount = NSPasteboard.general.changeCount
        
        // No change - check expiration periodically (every ~10 ticks = 5s)
        guard currentChangeCount != lastChangeCount else {
            if Int.random(in: 0..<10) == 0 {
                store?.checkExpiration()
            }
            return
        }
        
        lastChangeCount = currentChangeCount
        
        // Capture source app metadata
        let sourceApp = NSWorkspace.shared.frontmostApplication
        let sourceBundleID = sourceApp?.bundleIdentifier
        let sourceAppName = sourceApp?.localizedName
        
        // Extract and store
        if let item = extractClipboardItem() {
            store?.addItem(
                content: item.content,
                type: item.type,
                sourceBundleID: sourceBundleID,
                sourceAppName: sourceAppName,
                imageData: item.imageData
            )
        }
    }
    
    private func extractClipboardItem() -> (content: String, type: ClipboardHistoryStore.ClipboardItem.ItemType, imageData: Data?)? {
        let pasteboard = NSPasteboard.general
        
        // Priority 1: Images - REGRESSION FIX
        // NSImage(pasteboard:) can fail silently for certain formats.
        // Instead, read raw image data from explicit types (.tiff, .png) and convert to PNG.
        if let types = pasteboard.types {
            // Check for TIFF data first (most common macOS clipboard image format)
            if types.contains(.tiff), let tiffData = pasteboard.data(forType: .tiff) {
                if let bitmapRep = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                    return ("[Image]", .image, pngData)
                }
            }
            // Fallback: PNG data
            if types.contains(.png), let pngData = pasteboard.data(forType: .png) {
                return ("[Image]", .image, pngData)
            }
        }
        
        // Priority 2: URL
        if let urlString = pasteboard.string(forType: .URL), !urlString.isEmpty {
            return (urlString, .url, nil)
        }
        
        // Priority 3: Plain text
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            
            // Check if it's a color (hex)
            if trimmed.hasPrefix("#") && (trimmed.count == 7 || trimmed.count == 9) {
                return (trimmed, .color, nil)
            }
            
            // Check if it's a URL
            if let url = URL(string: trimmed), url.scheme != nil {
                return (trimmed, .url, nil)
            }
            
            // Detect code (heuristic: contains brackets/braces/semicolons)
            let codeIndicators = ["{", "}", "[", "]", ";", "function", "def ", "class ", "import", "const ", "let ", "var "]
            if codeIndicators.contains(where: { trimmed.contains($0) }) {
                return (trimmed, .code, nil)
            }
            
            return (trimmed, .text, nil)
        }
        
        return nil
    }
    
    deinit {
        stop()
    }
}
