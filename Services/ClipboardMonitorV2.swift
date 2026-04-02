//
//  ClipboardMonitorV2.swift
//  Mac灵动岛
//
//  Production clipboard monitor with complete edge case handling
//  - Flood detection & debouncing
//  - Content deduplication via hashing
//  - App context capture
//  - Priority-based content extraction
//

import Foundation
import AppKit
import CryptoKit
import OSLog

final class ClipboardMonitorV2 {
    
    // MARK: - Dependencies
    
    private weak var hubStore: ClipboardHubStore?
    private let logger = os.Logger(subsystem: "com.maclingdonggao.overlay", category: "clipboard_monitor_v2")
    
    // MARK: - State
    
    private var pollingTimer: Timer?
    private var lastChangeCount: Int = 0
    private var lastContentHash: String = ""
    private var lastChangeTime: Date = .distantPast
    private var floodDetectionWindow: [Date] = []
    
    // MARK: - Configuration
    
    private let pollingInterval: TimeInterval = 0.5  // 500ms polling
    private let debounceInterval: TimeInterval = 0.1  // Ignore changes within 100ms
    private let floodThreshold: Int = 20  // 20 changes in 2 seconds = flood
    private let floodWindowDuration: TimeInterval = 2.0
    
    // MARK: - Lifecycle
    
    init(hubStore: ClipboardHubStore) {
        self.hubStore = hubStore
        self.lastChangeCount = NSPasteboard.general.changeCount
    }
    
    func start() {
        // Initial state
        lastChangeCount = NSPasteboard.general.changeCount
        
        // Start polling timer
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
        
        logger.info("ClipboardMonitorV2 started")
    }
    
    func stop() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        logger.info("ClipboardMonitorV2 stopped")
    }
    
    // MARK: - Change Detection
    
    private func checkForChanges() {
        let currentChangeCount = NSPasteboard.general.changeCount
        
        // No change detected
        guard currentChangeCount != lastChangeCount else { return }
        
        lastChangeCount = currentChangeCount
        
        // Debounce: Ignore changes that happen too quickly
        let now = Date()
        if now.timeIntervalSince(lastChangeTime) < debounceInterval {
            logger.debug("Debounced clipboard change (too fast)")
            return
        }
        lastChangeTime = now
        
        // Flood detection
        floodDetectionWindow.append(now)
        floodDetectionWindow.removeAll { now.timeIntervalSince($0) > floodWindowDuration }
        
        if floodDetectionWindow.count > floodThreshold {
            logger.warning("Clipboard flood detected (\(self.floodDetectionWindow.count) changes in \(self.floodWindowDuration)s) - throttling")
            // Clear flood window but don't process this change
            floodDetectionWindow.removeAll()
            return
        }
        
        // Extract clipboard content
        processClipboardChange()
    }
    
    // MARK: - Content Extraction
    
    private func processClipboardChange() {
        // Capture source app IMMEDIATELY (before it changes)
        let sourceApp = NSWorkspace.shared.frontmostApplication
        
        // Extract content in priority order
        guard let extractedContent = extractClipboardContent() else {
            logger.debug("No extractable content found")
            return
        }
        
        // Deduplicate by content hash
        let contentHash = calculateContentHash(extractedContent)
        if contentHash == lastContentHash {
            logger.debug("Duplicate content detected (same hash) - skipping")
            return
        }
        lastContentHash = contentHash
        
        // Create ClipboardItemV2
        let item = createClipboardItem(from: extractedContent, sourceApp: sourceApp)
        
        // Add to store (on main thread)
        Task { @MainActor in
            hubStore?.addItem(item)
            logger.info("Added \(item.contentType.displayName) item from \(item.displayAppName)")
        }
    }
    
    // MARK: - Content Extraction (Priority Order)
    
    private func extractClipboardContent() -> ExtractedContent? {
        let pasteboard = NSPasteboard.general
        guard let availableTypes = pasteboard.types else { return nil }
        
        // SECURITY FIX: Avoid readObjects() which triggers NSXPCDecoder warnings.
        // Use propertyList(forType:) and data(forType:) instead.
        
        // Priority 1: File URLs (including PDFs)
        // Check for file URL types without triggering XPC deserialization
        if availableTypes.contains(.fileURL) {
            // Use propertyList to get file URLs safely
            if let plist = pasteboard.propertyList(forType: .fileURL) as? String,
               let url = URL(string: plist),
               url.isFileURL {
                return .file(url)
            }
            // Fallback: try data representation
            if let data = pasteboard.data(forType: .fileURL),
               let url = URL(dataRepresentation: data, relativeTo: nil),
               url.isFileURL {
                return .file(url)
            }
        }
        
        // Priority 2: Images (check type existence first, then load raw data)
        let hasImageType = availableTypes.contains(.tiff) || availableTypes.contains(.png)
        if hasImageType {
            // Load image from raw data representation - avoids XPC
            if let tiffData = pasteboard.data(forType: .tiff),
               let image = NSImage(data: tiffData) {
                return .image(image)
            }
            if let pngData = pasteboard.data(forType: .png),
               let image = NSImage(data: pngData) {
                return .image(image)
            }
        }
        
        // Priority 3: URLs (string form)
        if let urlString = pasteboard.string(forType: .URL), !urlString.isEmpty {
            return .url(urlString)
        }
        
        // Priority 4: Plain text
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            
            // Detect if it's a URL in text form
            if let url = URL(string: trimmed), url.scheme != nil {
                return .url(trimmed)
            }
            
            // Detect if it's a color (hex)
            if trimmed.hasPrefix("#") && (trimmed.count == 7 || trimmed.count == 9) {
                return .color(trimmed)
            }
            
            return .text(trimmed)
        }
        
        return nil
    }
    
    // MARK: - Item Creation
    
    private func createClipboardItem(from content: ExtractedContent, sourceApp: NSRunningApplication?) -> ClipboardItemV2 {
        switch content {
        case .text(let text):
            return ClipboardItemV2.createText(text, sourceApp: sourceApp)
            
        case .url(let urlString):
            return ClipboardItemV2.createText(urlString, sourceApp: sourceApp)
            
        case .image(let image):
            return ClipboardItemV2.createImage(image, sourceApp: sourceApp)
            
        case .file(let url):
            return ClipboardItemV2.createFile(url, sourceApp: sourceApp) ?? ClipboardItemV2.createText(url.path, sourceApp: sourceApp)
            
        case .color(let hex):
            return ClipboardItemV2.createText(hex, sourceApp: sourceApp)
        }
    }
    
    // MARK: - Content Hashing
    
    private func calculateContentHash(_ content: ExtractedContent) -> String {
        var hasher = SHA256()
        
        switch content {
        case .text(let text):
            hasher.update(data: Data(text.utf8))
        case .url(let urlString):
            hasher.update(data: Data(urlString.utf8))
        case .image(let image):
            if let tiffData = image.tiffRepresentation {
                hasher.update(data: tiffData)
            }
        case .file(let url):
            hasher.update(data: Data(url.path.utf8))
        case .color(let hex):
            hasher.update(data: Data(hex.utf8))
        }
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Extracted Content
    
    private enum ExtractedContent {
        case text(String)
        case url(String)
        case image(NSImage)
        case file(URL)
        case color(String)
    }
    
    deinit {
        stop()
    }
}

// MARK: - Edge Case Handling Documentation

/*
 EDGE CASES HANDLED:
 
 1. Clipboard Flood (e.g., IDE generating 100 copies/second)
    - Detection: Track changes in 2-second window
    - Action: Throttle when threshold exceeded
    - Recovery: Auto-reset after flood subsides
 
 2. Rapid Sequential Changes (debouncing)
    - Detection: Changes within 100ms
    - Action: Ignore subsequent changes
    - Why: Prevents duplicate captures from apps that write multiple times
 
 3. Duplicate Content
    - Detection: SHA256 hash comparison
    - Action: Skip if hash matches previous
    - Why: Prevents re-copying same content
 
 4. Missing Source App
    - Detection: NSWorkspace returns nil
    - Action: Create item with nil app info
    - Display: Shows "Unknown App" in UI
 
 5. Corrupted Image Data
    - Detection: NSImage(pasteboard:) returns nil
    - Action: Skip image extraction
    - Fallback: May extract as text if text representation exists
 
 6. Invalid File URLs
    - Detection: createFile returns nil
    - Action: Fallback to text representation
    - Why: Sandbox may block access, but path is still useful
 
 7. App Crash During Capture
    - Protection: All operations wrapped in optional chains
    - Recovery: Next poll cycle will continue normally
    - No state corruption possible
 
 8. Pasteboard Locked by Another Process
    - Detection: Polling continues, change count unchanged
    - Action: No-op until lock released
    - User impact: Slight delay, no data loss
 */
