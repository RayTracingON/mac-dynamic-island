import Foundation
import AppKit
import Combine
import SwiftUI

// MARK: - IslandClipItem
struct IslandClipItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let type: ItemType
    let timestamp: Date
    let sourceBundleID: String?
    let sourceAppName: String?
    let imageData: Data?
    
    enum ItemType: String, Codable {
        case text, image, url, code
    }
    
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var sourceIcon: NSImage {
        if let bundleID = sourceBundleID,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }
        return NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil) ?? NSImage()
    }

    static func == (lhs: IslandClipItem, rhs: IslandClipItem) -> Bool {
        return lhs.id == rhs.id
    }

    init(id: UUID = UUID(), content: String, type: ItemType, timestamp: Date = Date(), sourceBundleID: String?, sourceAppName: String?, imageData: Data?) {
        self.id = id
        self.content = content
        self.type = type
        self.timestamp = timestamp
        self.sourceBundleID = sourceBundleID
        self.sourceAppName = sourceAppName
        self.imageData = imageData
    }
}

// MARK: - ClipboardHubStore (The Island functional vault)
@MainActor
final class ClipboardHubStore: ObservableObject {
    @Published var items: [IslandClipItem] = []

    private let defaults: UserDefaults
    static let historyKey = "mac_island_clipvault_v1"
    private static let maxItemsKey = "clipboardMaxItems"
    private static let ttlHoursKey = "clipboardTTLHours"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        maxItems = defaults.object(forKey: Self.maxItemsKey) as? Int ?? 50
        ttlHours = defaults.object(forKey: Self.ttlHoursKey) as? Int ?? 0
    }

    /// How many items the history keeps; older ones drop off
    @Published var maxItems: Int {
        didSet {
            defaults.set(maxItems, forKey: Self.maxItemsKey)
            applyLimits()
        }
    }
    /// How long an item stays in the history, in hours; 0 keeps it until it drops off the end
    @Published var ttlHours: Int {
        didSet {
            defaults.set(ttlHours, forKey: Self.ttlHoursKey)
            applyLimits()
        }
    }

    /// Drops what's over maxItems and what's older than ttlHours
    func applyLimits() {
        let kept = limited(items)
        guard kept.count != items.count else { return }
        withAnimation { items = kept }
        saveToDisk()
    }

    private func limited(_ items: [IslandClipItem]) -> [IslandClipItem] {
        var kept = Array(items.prefix(maxItems))
        if ttlHours > 0 {
            let cutoff = Date().addingTimeInterval(-Double(ttlHours) * 3600)
            kept.removeAll { $0.timestamp < cutoff }
        }
        return kept
    }

    func addItem(content: String, type: IslandClipItem.ItemType, sourceBundleID: String?, sourceAppName: String?, imageData: Data?) {
        // Images all share the "[Image]" placeholder content, so their bytes must be compared as well
        let isSame = { (item: IslandClipItem) in
            item.content == content && item.type == type && item.imageData == imageData
        }
        if let last = items.first, isSame(last) { return }

        let newItem = IslandClipItem(
            id: UUID(),
            content: content,
            type: type,
            timestamp: Date(),
            sourceBundleID: sourceBundleID,
            sourceAppName: sourceAppName,
            imageData: imageData
        )
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            // Copied again, or pasted from the island: it moves to the front instead of showing twice
            items.removeAll(where: isSame)
            items.insert(newItem, at: 0)
            items = limited(items)
        }
        saveToDisk()
    }
    
    func clearAll() {
        withAnimation { items.removeAll() }
        saveToDisk()
    }
    
    /// Pastes the item into `app`, the app you were using. Clicking the card brought this app to the front,
    /// so that one comes back first, or the ⌘V would land in the island
    func pasteItem(_ item: IslandClipItem, into app: NSRunningApplication?) {
        copyToClipboard(item)
        guard let app, !app.isTerminated else { return }
        app.activate(options: [])
        Task {
            // Activating takes a moment. If it doesn't come forward the item stays on the clipboard,
            // rather than being pasted into whatever is in front
            var isInFront: Bool { NSWorkspace.shared.frontmostApplication?.processIdentifier == app.processIdentifier }
            for _ in 0..<20 {
                if isInFront { break }
                try? await Task.sleep(for: .milliseconds(25))
            }
            guard isInFront else { return }
            // Its window becomes key just after
            try? await Task.sleep(for: .milliseconds(50))
            // Off the main thread: an Apple Event can wait on a permission prompt
            _ = await AppleScriptHelper.execute(Self.pasteScript)
        }
    }

    private static let pasteScript = """
        tell application "System Events"
            keystroke "v" using {command down}
        end tell
        """
    
    func copyToClipboard(_ item: IslandClipItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        
        switch item.type {
        case .image:
            if let data = item.imageData, let img = NSImage(data: data) {
                pb.writeObjects([img])
            }
        default:
            pb.setString(item.content, forType: .string)
        }
    }
    
    private func saveToDisk() {
        if let data = try? JSONEncoder().encode(items) {
            defaults.set(data, forKey: Self.historyKey)
        }
    }

    func loadFromDisk() {
        if let data = defaults.data(forKey: Self.historyKey),
           let decoded = try? JSONDecoder().decode([IslandClipItem].self, from: data) {
            items = decoded
            // Items may have expired while the app wasn't running
            applyLimits()
        }
    }
}
