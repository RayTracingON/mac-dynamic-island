import Foundation
import AppKit

struct TrayItem: Identifiable, Codable {
    enum ItemKind: String, Codable {
        case file
        case app
    }

    let id: UUID
    let filePath: String
    let displayName: String
    let kind: ItemKind

    init(id: UUID = UUID(), filePath: String, displayName: String? = nil, kind: ItemKind? = nil) {
        self.id = id
        self.filePath = filePath
        self.displayName = displayName ?? URL(fileURLWithPath: filePath).lastPathComponent
        
        // Auto-detect app bundles
        if let kind = kind {
            self.kind = kind
        } else {
            self.kind = filePath.hasSuffix(".app") ? .app : .file
        }
    }

    var url: URL {
        URL(fileURLWithPath: filePath)
    }

    var fileExists: Bool {
        FileManager.default.fileExists(atPath: filePath)
    }

    var isApp: Bool {
        kind == .app
    }

    func getIcon() -> NSImage {
        TrayStore.getIconImage(for: url)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case filePath
        case displayName
        case kind
    }
}
