import Foundation
import AppKit

enum TrayStore {
    private static let trayKey = "mac_lingdonggao_tray_items"
    private static var iconCache: [String: NSImage] = [:]

    // MARK: - Persistence

    static func loadTrayItems() -> [TrayItem] {
        guard let data = UserDefaults.standard.data(forKey: trayKey) else {
            return []
        }
        let decoder = JSONDecoder()
        do {
            let items = try decoder.decode([TrayItem].self, from: data)
            // Filter out missing files but keep them in model (they'll show as "Missing")
            return items
        } catch {
            print("Error decoding tray items: \(error)")
            return []
        }
    }

    static func saveTrayItems(_ items: [TrayItem]) {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(items)
            UserDefaults.standard.set(data, forKey: trayKey)
        } catch {
            print("Error encoding tray items: \(error)")
        }
    }

    // MARK: - Icon Handling

    static func getIconImage(for url: URL) -> NSImage {
        let path = url.path
        if let cached = iconCache[path] {
            return cached
        }

        let workspace = NSWorkspace.shared
        let icon = workspace.icon(forFile: path)
        icon.size = NSSize(width: 128, height: 128) // Ensure high-res
        iconCache[path] = icon
        return icon
    }

    static func clearIconCache() {
        iconCache.removeAll()
    }

    // MARK: - Helpers

    static func createTrayItem(from url: URL) -> TrayItem {
        let displayName = url.lastPathComponent
        return TrayItem(filePath: url.path, displayName: displayName)
    }
}
