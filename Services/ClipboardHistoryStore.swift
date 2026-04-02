import Foundation
import Combine
import AppKit
import OSLog

/// Clipboard History Store - 4-state interaction model
/// States: Silent → Copy Confirmation → Intent Peek / Focused Recall → Silent
final class ClipboardHistoryStore: ObservableObject {
    
    // MARK: - Published State
    
    @Published var items: [ClipboardItem] = []
    @Published var isShowingToast: Bool = false  // Copy Confirmation state
    @Published var isShowingPicker: Bool = false // Intent Peek / Focused Recall
    @Published var pickerMode: PickerMode = .intentPeek
    @Published var isPinned: Bool = false
    
    private let logger = os.Logger(subsystem: "com.maclingdonggao.overlay", category: "clipboard_history")
    
    enum PickerMode {
        case intentPeek      // Show 2-3 recent items, no scroll
        case focusedRecall   // Show 6-8 items, scrollable
    }
    
    // MARK: - Configuration
    
    private let maxStoredItems = 10
    private let expirationInterval: TimeInterval = 86400 // 24 hours, not 5 minutes
    
    // MARK: - Clipboard Item Model
    
    struct ClipboardItem: Identifiable, Equatable {
        let id = UUID()
        let content: String
        let type: ItemType
        let timestamp: Date
        let sourceBundleIdentifier: String?
        let sourceAppName: String?
        let imageData: Data?  // For image clipboard items
        
        enum ItemType: String {
            case text
            case url
            case code  // Monospaced preview
            case image
            case color
        }
        
        static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
            lhs.id == rhs.id
        }
        
        /// Smart preview: remove line breaks, cap at 50 chars, no quotes
        var preview: String {
            let cleaned = content
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")
                .replacingOccurrences(of: "\t", with: " ")
                .replacingOccurrences(of: "  ", with: " ") // collapse double spaces
                .trimmingCharacters(in: .whitespaces)
            
            let maxLength = 50
            if cleaned.count > maxLength {
                return String(cleaned.prefix(maxLength)) + "…"
            }
            return cleaned
        }
        
        var icon: String {
            switch type {
            case .text: return "doc.plaintext"
            case .url: return "link"
            case .code: return "chevron.left.forwardslash.chevron.right"
            case .image: return "photo"
            case .color: return "paintpalette"
            }
        }
        
        /// Get source app icon (fallback to generic icon)
        var sourceIcon: NSImage {
            if let bundleID = sourceBundleIdentifier,
               let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                return NSWorkspace.shared.icon(forFile: appURL.path)
            }
            return NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil) ?? NSImage()
        }
        
        /// Display app name with fallback
        var displayAppName: String {
            sourceAppName ?? "Unknown App"
        }
        
        /// Relative time string (e.g., "now", "2m", "1h", "2d")
        var relativeTime: String {
            let interval = Date().timeIntervalSince(timestamp)
            
            if interval < 5 {
                return "now"
            } else if interval < 60 {
                return "\(Int(interval))s"
            } else if interval < 3600 {
                return "\(Int(interval / 60))m"
            } else if interval < 86400 {
                return "\(Int(interval / 3600))h"
            } else {
                return "\(Int(interval / 86400))d"
            }
        }
        
        /// Normalized content for semantic similarity
        var normalizedContent: String {
            var normalized = content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // For URLs: strip common tracking params
            if type == .url, let url = URL(string: normalized) {
                if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    // Remove tracking query params
                    components.queryItems = components.queryItems?.filter { item in
                        let trackingParams = ["utm_source", "utm_medium", "utm_campaign", 
                                              "utm_term", "utm_content", "fbclid", "gclid"]
                        return !trackingParams.contains(item.name.lowercased())
                    }
                    if let cleanedURL = components.url {
                        normalized = cleanedURL.absoluteString
                    }
                }
            }
            
            return normalized
        }
    }
    
    // MARK: - Timers
    
    private var toastDismissalTimer: Timer?
    private var lastCopyTime: Date = .distantPast
    
    /// Check if we're within "intent window" (2s after copy)
    private var isInIntentWindow: Bool {
        Date().timeIntervalSince(lastCopyTime) < 2.0
    }
    
    // MARK: - Public API
    
    /// Add a new clipboard item (called by monitor)
    func addItem(content: String, type: ClipboardItem.ItemType, sourceBundleID: String? = nil, sourceAppName: String? = nil, imageData: Data? = nil) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || imageData != nil else { return }
        
        let newItem = ClipboardItem(
            content: trimmed,
            type: type,
            timestamp: Date(),
            sourceBundleIdentifier: sourceBundleID,
            sourceAppName: sourceAppName,
            imageData: imageData
        )
        
        // Deduplicate by normalized content: move existing to front
        if let existingIndex = items.firstIndex(where: { $0.normalizedContent == newItem.normalizedContent }) {
            let existing = items.remove(at: existingIndex)
            items.insert(existing, at: 0)
        } else {
            items.insert(newItem, at: 0)
        }
        lastCopyTime = Date()
        
        // Enforce max
        if items.count > maxStoredItems {
            items.removeLast(items.count - maxStoredItems)
        }
        
        // Show toast (Copy Confirmation state)
        showToast()
        
        #if DEBUG
        logger.debug("Added \(type.rawValue) (total: \(self.items.count))")
        #endif
    }
    
    /// Restore an item to system clipboard
    func restoreItem(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
        
        #if DEBUG
        logger.debug("Restored item")
        #endif
    }
    
    /// Clear all history
    func clearAll() {
        // ✅ 直接同步执行，不用 async
        items = []  // 直接赋值空数组，触发 @Published
        hidePicker()
        
        #if DEBUG
        logger.debug("✅ Cleared all")
        #endif
    }
    
    /// Show toast for 1.0 second (Copy Confirmation state)
    func showToast() {
        isShowingToast = true
        
        toastDismissalTimer?.invalidate()
        toastDismissalTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.hideToast()
        }
    }
    
    /// Hide toast
    func hideToast() {
        isShowingToast = false
        toastDismissalTimer?.invalidate()
    }
    
    /// Show picker with mode detection
    func showPicker() {
        guard !items.isEmpty else { return }
        
        // Auto-detect mode based on context
        if isInIntentWindow {
            pickerMode = .intentPeek  // Show 2-3 items, triggered from toast
        } else {
            pickerMode = .focusedRecall  // Show 6-8 items, triggered from menu/hotkey
        }
        
        isShowingPicker = true
        hideToast() // Toast and picker are mutually exclusive
    }
    
    /// Show picker with explicit mode (for menu/hotkey)
    func showPickerExplicit(mode: PickerMode) {
        guard !items.isEmpty else { return }
        pickerMode = mode
        isShowingPicker = true
        hideToast()
    }
    
    /// Hide picker
    func hidePicker() {
        isShowingPicker = false
        isPinned = false
    }
    
    /// Toggle pin state
    func togglePin() {
        isPinned.toggle()
    }
    
    /// Get displayable items based on picker mode
    var displayableItems: [ClipboardItem] {
        switch pickerMode {
        case .intentPeek:
            return Array(items.prefix(3))  // Show 2-3 recent items only
        case .focusedRecall:
            return Array(items.prefix(8))  // Show up to 8 items
        }
    }
    
    /// Get most recent item (for toast preview)
    var latestItem: ClipboardItem? {
        items.first
    }
    
    /// Check for expiration
    func checkExpiration() {
        let now = Date()
        items.removeAll { item in
            now.timeIntervalSince(item.timestamp) > expirationInterval
        }
    }
    
    deinit {
        toastDismissalTimer?.invalidate()
    }
}
