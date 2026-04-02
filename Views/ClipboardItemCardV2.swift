//
//  ClipboardItemCardV2.swift
//  Mac灵动岛
//
//  Premium clipboard card with rich previews, hover actions, drag support
//

import SwiftUI
import AppKit

struct ClipboardItemCardV2: View {
    let item: IslandClipItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onCopy: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            // Interactive Container
            VStack(alignment: .leading, spacing: 0) {
                // Header: App icon + name + time
                CardHeader(item: item)
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
                
                // Content preview
                CardContent(item: item)
                    .padding(.horizontal, 14)
                    .frame(height: 100, alignment: .top)
                
                Spacer(minLength: 0)
                
                // Footer: Badge + actions
                CardFooter(
                    item: item,
                    isHovered: isHovered,
                    onPin: onPin,
                    onDelete: onDelete
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
                .padding(.top, 4)
            }
            .frame(minHeight: 180)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        isSelected 
                        ? Color(white: 0.14) 
                        : (isHovered ? Color(white: 0.08) : Color.clear)
                    )
                     // Zero strokes. Zero shadows.
            )
            // Selection Ring only when active
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        isSelected ? IslandStyleTokens.accent.opacity(0.8) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            // Interaction Spring
            .scaleEffect(isHovered ? 0.98 : 1.0)
            .animation(IslandStyleTokens.contentAnimation, value: isHovered)
            .onHover { hovering in
                // Immediate response, no fade lag
                isHovered = hovering
            }
            .onTapGesture {
                onSelect()
                onCopy()
            }
            .onDrag {
                provideDragItem()
            }
        }
    }
    
    // MARK: - Drag Support
    
    private func provideDragItem() -> NSItemProvider {
        let provider = NSItemProvider()
        
        switch item.contentType {
        case .text, .richText, .code:
            if let text = item.text {
                provider.registerDataRepresentation(forTypeIdentifier: "public.utf8-plain-text", visibility: .all) { completion in
                    completion(text.data(using: .utf8), nil)
                    return nil
                }
            }
            
        case .url:
            if let urlString = item.urlString, let url = URL(string: urlString) {
                provider.registerDataRepresentation(forTypeIdentifier: "public.url", visibility: .all) { completion in
                    completion(url.dataRepresentation, nil)
                    return nil
                }
            }
            
        case .image:
            if let imageData = item.imageData {
                provider.registerDataRepresentation(forTypeIdentifier: "public.png", visibility: .all) { completion in
                    completion(imageData, nil)
                    return nil
                }
            }
            
        case .file, .pdf:
            if let bookmark = item.fileBookmark {
                var isStale = false
                if let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale) {
                    _ = url.startAccessingSecurityScopedResource()
                    provider.registerFileRepresentation(forTypeIdentifier: "public.file-url", visibility: .all) { completion in
                        completion(url, false, nil)
                        url.stopAccessingSecurityScopedResource()
                        return nil
                    }
                }
            }
            
        case .color:
            if let hex = item.colorHex {
                provider.registerDataRepresentation(forTypeIdentifier: "public.utf8-plain-text", visibility: .all) { completion in
                    completion(hex.data(using: .utf8), nil)
                    return nil
                }
            }
            
        case .unknown:
            break
        }
        
        return provider
    }
}

// MARK: - Card Header

private struct CardHeader: View {
    let item: IslandClipItem
    
    var body: some View {
        HStack(spacing: 6) {
            // App icon
            Image(nsImage: item.sourceAppIcon())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .cornerRadius(3)
            
            // App name
            Text(item.displayAppName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(IslandStyleTokens.secondaryText)
                .lineLimit(1)
            
            Spacer(minLength: 4)
            
            // Relative time
            Text(item.relativeTimeString)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(IslandStyleTokens.tertiaryText)
        }
    }
}

// MARK: - Card Content

private struct CardContent: View {
    let item: IslandClipItem
    
    var body: some View {
        Group {
            switch item.contentType {
            case .text, .richText:
                TextPreview(text: item.text ?? "")
                
            case .code:
                CodePreview(code: item.text ?? "")
                
            case .url:
                URLPreview(urlString: item.urlString ?? "")
                
            case .image:
                ImagePreview(imageData: item.imageData)
                
            case .file, .pdf:
                FilePreview(item: item)
                
            case .color:
                ColorPreview(hex: item.colorHex ?? "#000000")
                
            case .unknown:
                UnknownPreview()
            }
        }
    }
}

// MARK: - Preview Types

private struct TextPreview: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(.white)
            .lineLimit(6)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct CodePreview: View {
    let code: String
    
    var body: some View {
        Text(code)
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(.primary.opacity(0.9))
            .lineLimit(7)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(nsColor: .textBackgroundColor).opacity(0.5))
            )
    }
}

private struct URLPreview: View {
    let urlString: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(urlString)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct ImagePreview: View {
    let imageData: Data?
    
    var body: some View {
        if let data = imageData, let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .cornerRadius(8)
        } else {
            PlaceholderView(icon: "photo", text: "Image")
        }
    }
}

private struct FilePreview: View {
    let item: IslandClipItem
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: item.contentType == .pdf ? "doc.text.fill" : "doc.fill")
                .font(.system(size: 36))
                .foregroundColor(.orange.opacity(0.8))
            
            if let fileName = item.fileDisplayName {
                Text(fileName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            
            if let size = item.fileSizeBytes {
                Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ColorPreview: View {
    let hex: String
    
    var body: some View {
        if let color = colorFromHex(hex) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(hex.uppercased())
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.4))
                            )
                            .padding(8)
                    }
                }
            }
        } else {
            PlaceholderView(icon: "paintpalette", text: hex)
        }
    }
    
    private func colorFromHex(_ hex: String) -> Color? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        return Color(red: r, green: g, blue: b)
    }
}

private struct UnknownPreview: View {
    var body: some View {
        PlaceholderView(icon: "questionmark.circle", text: "Unknown Content")
    }
}

private struct PlaceholderView: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Card Footer

private struct CardFooter: View {
    let item: IslandClipItem
    let isHovered: Bool
    let onPin: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Type badge
            TypeBadge(contentType: item.contentType)
            
            // Size info
            if !item.sizeInfo.isEmpty {
                Text(item.sizeInfo)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(IslandStyleTokens.tertiaryText)
            }
            
            Spacer()
            
            // Hover actions
            if isHovered {
                HoverActions(item: item, onPin: onPin, onDelete: onDelete)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

private struct TypeBadge: View {
    let contentType: ClipboardItemV2.ContentType
    
    var body: some View {
        Text(contentType.displayName.uppercased())
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color(contentType.badgeColor).opacity(0.8)) // Less opaque for blending
            )
    }
}

private struct HoverActions: View {
    let item: IslandClipItem
    let onPin: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            // Pin button
            Button(action: onPin) {
                Image(systemName: item.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(item.isPinned ? IslandStyleTokens.accent : IslandStyleTokens.secondaryText)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .allowsHitTesting(true)
            .help(item.isPinned ? "Unpin" : "Pin")
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red.opacity(0.9)) // Keep red for destructive actions
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .allowsHitTesting(true)
            .help("Delete")
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ClipboardItemCardV2_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 16) {
            // Text card
            ClipboardItemCardV2(
                item: IslandClipItem.mockText("Hello, world! This is a longer text to demonstrate the preview truncation behavior."),
                isSelected: false,
                onSelect: {},
                onCopy: {},
                onPin: {},
                onDelete: {}
            )
            .frame(width: 200)
            
            // URL card
            ClipboardItemCardV2(
                item: IslandClipItem.mockText("https://github.com/example/repository"),
                isSelected: true,
                onSelect: {},
                onCopy: {},
                onPin: {},
                onDelete: {}
            )
            .frame(width: 200)
            
            // Color card
            ClipboardItemCardV2(
                item: IslandClipItem.mockText("#FF5733"),
                isSelected: false,
                onSelect: {},
                onCopy: {},
                onPin: {},
                onDelete: {}
            )
            .frame(width: 200)
        }
        .padding(40)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

extension IslandClipItem {
    static func mockText(_ text: String) -> IslandClipItem {
        IslandClipItem(
            content: text,
            type: text.hasPrefix("#") ? .text : (text.hasPrefix("http") ? .url : .text),
            sourceBundleID: "com.apple.Safari",
            sourceAppName: "Safari",
            imageData: nil
        )
    }
}
#endif
