//
//  ClipboardItemV2.swift
//  Mac灵动岛
//
//  Premium Clipboard Item Model - Rich metadata for Deck-class functionality
//

import Foundation
import AppKit
import CryptoKit

// MARK: - Clipboard Item V2

struct ClipboardItemV2: Identifiable, Codable, Equatable {
    
    // MARK: - Schema Version
    
    /// Schema version for safe migration
    /// Version 1: Initial release with 9 content types
    let schemaVersion: Int
    
    // MARK: - Identity
    
    let id: UUID
    let timestamp: Date
    
    // MARK: - Source Metadata
    
    let sourceAppBundleID: String?
    let sourceAppName: String?
    let sourceAppIconData: Data?  // Cached app icon (small PNG)
    
    // MARK: - Content Type
    
    enum ContentType: String, Codable, CaseIterable {
        case text
        case richText
        case code
        case url
        case image
        case file
        case pdf
        case color
        case unknown
        
        var displayName: String {
            switch self {
            case .text: return "Text"
            case .richText: return "Rich Text"
            case .code: return "Code"
            case .url: return "Link"
            case .image: return "Image"
            case .file: return "File"
            case .pdf: return "PDF"
            case .color: return "Color"
            case .unknown: return "Unknown"
            }
        }
        
        var icon: String {
            switch self {
            case .text: return "doc.plaintext"
            case .richText: return "doc.richtext"
            case .code: return "chevron.left.forwardslash.chevron.right"
            case .url: return "link"
            case .image: return "photo"
            case .file: return "doc"
            case .pdf: return "doc.text"
            case .color: return "paintpalette"
            case .unknown: return "questionmark.circle"
            }
        }
        
        var badgeColor: NSColor {
            switch self {
            case .text: return .systemBlue
            case .richText: return .systemIndigo
            case .code: return .systemPurple
            case .url: return .systemGreen
            case .image: return .systemPink
            case .file: return .systemOrange
            case .pdf: return .systemRed
            case .color: return .systemYellow
            case .unknown: return .systemGray
            }
        }
    }
    
    let contentType: ContentType
    
    // MARK: - Payload (only one active based on type)
    
    /// Plain text content
    var text: String?
    
    /// Image data (PNG compressed)
    var imageData: Data?
    
    /// File bookmark (security-scoped)
    var fileBookmark: Data?
    
    /// File display name (cached)
    var fileDisplayName: String?
    
    /// File size in bytes
    var fileSizeBytes: Int?
    
    /// URL string
    var urlString: String?
    
    /// Color hex string (e.g., "#FF5733")
    var colorHex: String?
    
    // MARK: - Flags
    
    var isPinned: Bool
    var isSensitive: Bool  // Hide preview until authenticated
    
    // MARK: - Computed Properties
    
    /// Preview text (safe for display in lists)
    var previewText: String {
        switch contentType {
        case .text, .richText, .code:
            return text?.prefix(100).replacingOccurrences(of: "\n", with: " ") ?? ""
        case .url:
            return urlString ?? ""
        case .image:
            return "[Image]"
        case .file, .pdf:
            return fileDisplayName ?? "[File]"
        case .color:
            return colorHex ?? "#000000"
        case .unknown:
            return "[Unknown Content]"
        }
    }
    
    /// Size info string (e.g., "2.4 MB", "142 characters")
    var sizeInfo: String {
        switch contentType {
        case .text, .richText, .code:
            let count = text?.count ?? 0
            if count < 1000 {
                return "\(count) chars"
            } else {
                return String(format: "%.1f KB", Double(count) / 1024.0)
            }
        case .image:
            if let size = imageData?.count {
                return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            }
            return "Image"
        case .file, .pdf:
            if let size = fileSizeBytes {
                return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
            }
            return "File"
        case .url:
            return "Link"
        case .color:
            return "Color"
        case .unknown:
            return "--"
        }
    }
    
    /// Relative time string (e.g., "now", "2m ago", "3h ago")
    var relativeTimeString: String {
        let interval = Date().timeIntervalSince(timestamp)
        
        if interval < 5 {
            return "now"
        } else if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
    
    /// Source app icon (cached or fetched)
    func sourceAppIcon() -> NSImage {
        // Try cached icon data first
        if let iconData = sourceAppIconData, let icon = NSImage(data: iconData) {
            return icon
        }
        
        // Try to fetch from bundle ID
        if let bundleID = sourceAppBundleID,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }
        
        // Fallback to generic clipboard icon
        return NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil) ?? NSImage()
    }
    
    /// Display app name with fallback
    var displayAppName: String {
        sourceAppName ?? "Unknown App"
    }
    
    /// Searchable content (all text concatenated)
    var searchableContent: String {
        var components: [String] = []
        
        if let text = text {
            components.append(text)
        }
        if let url = urlString {
            components.append(url)
        }
        if let fileName = fileDisplayName {
            components.append(fileName)
        }
        if let appName = sourceAppName {
            components.append(appName)
        }
        
        return components.joined(separator: " ").lowercased()
    }
    
    /// Content hash for deduplication
    var contentHash: String {
        var hasher = SHA256()
        
        switch contentType {
        case .text, .richText, .code:
            if let text = text {
                hasher.update(data: Data(text.utf8))
            }
        case .url:
            if let url = urlString {
                hasher.update(data: Data(url.utf8))
            }
        case .image:
            if let data = imageData {
                hasher.update(data: data)
            }
        case .file, .pdf:
            if let bookmark = fileBookmark {
                hasher.update(data: bookmark)
            }
        case .color:
            if let hex = colorHex {
                hasher.update(data: Data(hex.utf8))
            }
        case .unknown:
            break
        }
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - NSColor Conversion
    
    /// Convert hex color string to NSColor
    func nsColor() -> NSColor? {
        guard contentType == .color, let hex = colorHex else { return nil }
        
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: ClipboardItemV2, rhs: ClipboardItemV2) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Factory Methods
    
    /// Create text item
    static func createText(_ text: String, sourceApp: NSRunningApplication?) -> ClipboardItemV2 {
        let type: ContentType
        
        // Smart type detection
        if text.hasPrefix("#") && (text.count == 7 || text.count == 9) {
            type = .color
        } else if URL(string: text) != nil && (text.hasPrefix("http://") || text.hasPrefix("https://")) {
            type = .url
        } else if text.contains("{") || text.contains("func ") || text.contains("class ") {
            type = .code
        } else {
            type = .text
        }
        
        return ClipboardItemV2(
            schemaVersion: 1,
            id: UUID(),
            timestamp: Date(),
            sourceAppBundleID: sourceApp?.bundleIdentifier,
            sourceAppName: sourceApp?.localizedName,
            sourceAppIconData: sourceApp?.icon?.pngData(size: NSSize(width: 32, height: 32)),
            contentType: type,
            text: text,
            imageData: nil,
            fileBookmark: nil,
            fileDisplayName: nil,
            fileSizeBytes: nil,
            urlString: type == .url ? text : nil,
            colorHex: type == .color ? text : nil,
            isPinned: false,
            isSensitive: false
        )
    }
    
    /// Create image item
    static func createImage(_ image: NSImage, sourceApp: NSRunningApplication?) -> ClipboardItemV2 {
        let pngData = image.pngData(size: image.size)
        
        return ClipboardItemV2(
            schemaVersion: 1,
            id: UUID(),
            timestamp: Date(),
            sourceAppBundleID: sourceApp?.bundleIdentifier,
            sourceAppName: sourceApp?.localizedName,
            sourceAppIconData: sourceApp?.icon?.pngData(size: NSSize(width: 32, height: 32)),
            contentType: .image,
            text: nil,
            imageData: pngData,
            fileBookmark: nil,
            fileDisplayName: nil,
            fileSizeBytes: pngData?.count,
            urlString: nil,
            colorHex: nil,
            isPinned: false,
            isSensitive: false
        )
    }
    
    /// Create file item (with security-scoped bookmark)
    static func createFile(_ url: URL, sourceApp: NSRunningApplication?) -> ClipboardItemV2? {
        // Create security-scoped bookmark
        guard let bookmark = try? url.bookmarkData(
            options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else {
            return nil
        }
        
        let fileName = url.lastPathComponent
        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize
        
        let type: ContentType = url.pathExtension.lowercased() == "pdf" ? .pdf : .file
        
        return ClipboardItemV2(
            schemaVersion: 1,
            id: UUID(),
            timestamp: Date(),
            sourceAppBundleID: sourceApp?.bundleIdentifier,
            sourceAppName: sourceApp?.localizedName,
            sourceAppIconData: sourceApp?.icon?.pngData(size: NSSize(width: 32, height: 32)),
            contentType: type,
            text: nil,
            imageData: nil,
            fileBookmark: bookmark,
            fileDisplayName: fileName,
            fileSizeBytes: fileSize,
            urlString: nil,
            colorHex: nil,
            isPinned: false,
            isSensitive: false
        )
    }
}

// MARK: - NSImage Extension

extension NSImage {
    /// Convert NSImage to PNG Data with optional size constraint
    func pngData(size: NSSize? = nil) -> Data? {
        guard let targetSize = size else {
            // No resize, just convert
            guard let tiffData = self.tiffRepresentation,
                  let bitmapRep = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
                return nil
            }
            return pngData
        }
        
        // Resize and convert
        let resizedImage = NSImage(size: targetSize)
        resizedImage.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: targetSize))
        resizedImage.unlockFocus()
        
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        return pngData
    }
}
