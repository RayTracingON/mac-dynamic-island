//
//  ClipboardExpandedPanelView.swift
//  Mac灵动岛
//
//  Native Detail Panel used by ClipboardNativeView (right pane)
//  Focuses on preview + actions; not used as a grid layout
//

import SwiftUI
import AppKit

/// Large professional panel with three clear zones
/// Feels like Spotlight, AirDrop, Control Center - NOT a web dashboard
struct ClipboardExpandedPanelView: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    @EnvironmentObject var appState: AppState
    
    // Professional spacing constants
    private let outerPadding: CGFloat = 32
    private let sectionSpacing: CGFloat = 24
    
    var body: some View {
        VStack(spacing: 0) {
            // ZONE 1: TOP REEL (already handled by parent)
            // This view focuses on ZONE 2 (Main Content) and ZONE 3 (Actions)
            
            // ZONE 2: MAIN CONTENT (DOMINANT)
            mainContentZone
                .padding(.horizontal, outerPadding)
                .padding(.top, sectionSpacing)
            
            Spacer(minLength: 16)
            
            // ZONE 3: ACTIONS (SECONDARY)
            actionsZone
                .padding(.horizontal, outerPadding)
                .padding(.bottom, outerPadding)
        }
        .background(Color.clear)
    }
    
    // MARK: - ZONE 2: Main Content (Selected Item Preview)
    
    @ViewBuilder
    private var mainContentZone: some View {
        if let selectedID = hubStore.selectedItemID,
           let item = hubStore.items.first(where: { $0.id == selectedID }) {
            
            VStack(alignment: .leading, spacing: 16) {
                // Header: App + Type
                HStack(spacing: 12) {
                    Image(nsImage: item.sourceAppIcon())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.sourceAppName ?? "Unknown")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(item.relativeTimeString)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Type badge
                    typeBadge(for: item)
                }
                
                Divider()
                    .opacity(0.1)
                
                // Content preview - generous space
                ScrollView {
                    contentPreview(for: item)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 180)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
            )
        } else {
            // Empty state - calm, not aggressive
            VStack(spacing: 16) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundColor(.secondary.opacity(0.4))
                
                Text("Select an item to preview")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .frame(maxHeight: .infinity)
        }
    }
    
    // MARK: - ZONE 3: Actions (macOS Native Buttons)
    
    @ViewBuilder
    private var actionsZone: some View {
        if let selectedID = hubStore.selectedItemID,
           let item = hubStore.items.first(where: { $0.id == selectedID }) {
            
            HStack(spacing: 16) {
                // Secondary actions - system button style
                HStack(spacing: 12) {
                    Button(action: {
                        hubStore.togglePin(for: item)
                    }) {
                        Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash.fill" : "pin.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button(action: {
                        hubStore.removeItem(item)
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.red)
                }
                
                Spacer()
                
                // Primary action - prominent
                Button(action: {
                    hubStore.copyToClipboard(item)
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.return, modifiers: [])
            }
        }
    }

    // MARK: - Helper Views
    
    private func typeBadge(for item: IslandClipItem) -> some View {
        Text(badgeText(for: item))
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(badgeColor(for: item))
            )
    }
    
    private func badgeText(for item: IslandClipItem) -> String {
        switch item.contentType {
        case .text: return "Text"
        case .richText: return "Rich Text"
        case .code: return "Code"
        case .url: return "URL"
        case .image: return "Image"
        case .file: return "File"
        case .pdf: return "PDF"
        case .color: return "Color"
        case .unknown: return "Unknown"
        }
    }
    
    private func badgeColor(for item: IslandClipItem) -> Color {
        switch item.contentType {
        case .text, .richText: return .blue
        case .code: return .purple
        case .url: return .green
        case .image: return .pink
        case .file, .pdf: return .orange
        case .color: return .yellow
        case .unknown: return .gray
        }
    }
    
    @ViewBuilder
    private func contentPreview(for item: IslandClipItem) -> some View {
        switch item.contentType {
        case .text, .richText, .code:
            if let text = item.text {
                Text(text)
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
            }
        case .url:
            if let urlString = item.urlString {
                Link(destination: URL(string: urlString) ?? URL(string: "about:blank")!) {
                    Text(urlString)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.accentColor)
                        .underline()
                }
            }
        case .image:
            Text("[Image: \(item.sizeInfo)]")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
        case .file, .pdf:
            Text(item.fileDisplayName ?? "[File]")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.primary)
        case .color:
            HStack {
                if let hex = item.colorHex {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        // Fixed: Removed problematic label `hex:`
                        .fill(Color(hex: hex) ?? .gray)
                        .frame(width: 40, height: 40)
                    
                    Text(hex)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }
        case .unknown:
            Text("[Unknown Content Type]")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
        }
    }
}

// Ensure Color(hex:) initializer is available
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
