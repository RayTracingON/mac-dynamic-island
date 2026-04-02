//
//  ClipboardNativeView.swift
//  Mac灵动岛
//
//  NATIVE macOS CLIPBOARD BROWSER
//  Architecture: Sidebar | List | Detail (Finder-style)
//

import SwiftUI
import AppKit

/// Native three-column clipboard browser
/// LEFT: Navigation sidebar
/// CENTER: Item list
/// RIGHT: Detail/preview pane
struct ClipboardNativeView: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    @EnvironmentObject var appState: AppState
    @FocusState private var searchFocused: Bool
    
    var body: some View {
        NavigationSplitView {
            // LEFT: Sidebar
            ClipboardSidebar()
                .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
        } content: {
            // CENTER: List
            ClipboardList()
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } detail: {
            // RIGHT: Detail
            ClipboardDetail()
                .navigationSplitViewColumnWidth(min: 300, ideal: 380)
        }
        .navigationSplitViewStyle(.balanced)
        .clipboardKeyRouter(hubStore: hubStore, appState: appState)
    }
}

// MARK: - LEFT: Sidebar (Navigation)

private struct ClipboardSidebar: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    
    private struct NavSection: Identifiable {
        let id: String
        let title: String
        let icon: String
        let filter: SearchEngine.ContentFilter
        var count: Int
    }
    
    private var sections: [NavSection] {
        [
            NavSection(id: "all", title: "All Items", icon: "doc.on.clipboard", filter: .all, count: hubStore.totalItemCount),
            NavSection(id: "pinned", title: "Pinned", icon: "pin.fill", filter: .pinned, count: hubStore.pinnedItems.count),
            NavSection(id: "text", title: "Text", icon: "doc.text", filter: .text, count: hubStore.textItemCount),
            NavSection(id: "images", title: "Images", icon: "photo", filter: .images, count: hubStore.imageItemCount),
            NavSection(id: "links", title: "Links", icon: "link", filter: .links, count: hubStore.items.filter { $0.contentType == .url }.count),
            NavSection(id: "files", title: "Files", icon: "doc", filter: .files, count: hubStore.fileItemCount)
        ]
    }
    
    var body: some View {
        List {
            Section {
                ForEach(sections) { section in
                    Button(action: { hubStore.setFilter(section.filter) }) {
                        HStack(spacing: 10) {
                            Image(systemName: section.icon)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                                .frame(width: 16, alignment: .leading)
                            
                            Text(section.title)
                                .font(.system(size: 12))
                            
                            Spacer()
                            
                            if section.count > 0 {
                                Text("\(section.count)")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(section.filter == hubStore.currentFilter ? Color.accentColor.opacity(0.12) : Color.clear)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Clipboard")
    }
}

// MARK: - CENTER: List (Items)

private struct ClipboardList: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    @FocusState private var searchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Search toolbar
            searchToolbar
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Items list
            if hubStore.displayItems.isEmpty {
                emptyState
            } else {
                itemsList
            }
        }
    }
    
    private var searchToolbar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            TextField("Search", text: $hubStore.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .focused($searchFocused)
            
            if !hubStore.searchQuery.isEmpty {
                Button(action: { hubStore.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor))
        )
    }
    
    private var itemsList: some View {
        List(selection: $hubStore.selectedItemID) {
            ForEach(hubStore.displayItems) { item in
                ClipboardListRow(item: item)
                    .tag(item.id)
                    .contextMenu {
                        rowContextMenu(for: item)
                    }
            }
        }
        .listStyle(.plain)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 36, weight: .thin))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(emptyStateMessage)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateMessage: String {
        if !hubStore.searchQuery.isEmpty {
            return "No results found"
        } else if hubStore.currentFilter != .all {
            return "No \(hubStore.currentFilter.displayName.lowercased())"
        } else {
            return "Clipboard is empty"
        }
    }
    
    @ViewBuilder
    private func rowContextMenu(for item: IslandClipItem) -> some View {
        Button("Copy") {
            hubStore.copyToClipboard(item)
        }
        
        Divider()
        
        Button(item.isPinned ? "Unpin" : "Pin") {
            hubStore.togglePin(for: item)
        }
        
        Divider()
        
        Button("Delete") {
            hubStore.removeItem(item)
        }
    }
}

// MARK: - List Row

private struct ClipboardListRow: View {
    let item: IslandClipItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: item.contentType.systemIcon)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(item.contentType.accentColor)
                .frame(width: 20, alignment: .center)
            
            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(item.previewText)
                    .font(.system(size: 12))
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if let appName = item.sourceAppName {
                        Text(appName)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Text(item.relativeTimeString)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Pin indicator
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - RIGHT: Detail (Preview)

private struct ClipboardDetail: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    
    var body: some View {
        if let selectedID = hubStore.selectedItemID,
           let item = hubStore.items.first(where: { $0.id == selectedID }) {
            selectedItemDetail(item: item)
        } else {
            noSelectionView
        }
    }
    
    private var noSelectionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("No Selection")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("Select an item to view details")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func selectedItemDetail(item: IslandClipItem) -> some View {
        VStack(spacing: 0) {
            // Preview area
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Metadata section
                    metadataSection(for: item)
                    
                    Divider()
                    
                    // Content preview
                    contentPreview(for: item)
                }
                .padding(20)
            }
            
            Divider()
            
            // Actions
            actionBar(for: item)
                .padding(16)
        }
    }
    
    @ViewBuilder
    private func metadataSection(for item: IslandClipItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(nsImage: item.sourceAppIcon())
                    .resizable()
                    .frame(width: 32, height: 32)
                    .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.sourceAppName ?? "Unknown")
                        .font(.system(size: 13, weight: .semibold))
                    
                    Text(item.timestamp, style: .relative)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Type badge
                Text(item.contentType.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(item.contentType.accentColor)
                    )
            }
            
            // Additional metadata
            metadataRow(label: "Size", value: item.sizeInfo)
        }
    }
    
    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 11, design: .monospaced))
        }
    }
    
    @ViewBuilder
    private func contentPreview(for item: IslandClipItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            
            Group {
                switch item.contentType {
                case .text, .richText, .code:
                    if let text = item.text {
                        Text(text)
                            .font(.system(size: 12, design: item.contentType == .code ? .monospaced : .default))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                case .url:
                    if let urlString = item.urlString {
                        Link(urlString, destination: URL(string: urlString) ?? URL(string: "about:blank")!)
                            .font(.system(size: 12))
                    }
                    
                case .image:
                    if let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .cornerRadius(8)
                    }
                    
                case .file, .pdf:
                    if let fileName = item.fileDisplayName {
                        Text(fileName)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                case .color:
                    if let hex = item.colorHex {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: hex) ?? .gray)
                                .frame(width: 40, height: 40)
                            
                            Text(hex)
                                .font(.system(size: 12, design: .monospaced))
                        }
                    }
                    
                case .unknown:
                    Text("Preview unavailable")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .textBackgroundColor))
            )
        }
    }
    
    @ViewBuilder
    private func actionBar(for item: IslandClipItem) -> some View {
        HStack(spacing: 12) {
            Button(action: {
                hubStore.togglePin(for: item)
            }) {
                Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
            }
            .buttonStyle(.bordered)
            
            Button(action: {
                hubStore.removeItem(item)
            }) {
                Label("Delete", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .tint(.red)
            
            Spacer()
            
            Button(action: {
                hubStore.copyToClipboard(item)
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
            }) {
                Label("Copy", systemImage: "doc.on.doc")
                    .frame(minWidth: 80)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: [])
        }
    }
}

// MARK: - Extensions

extension ClipboardItemV2.ContentType {
    var systemIcon: String {
        switch self {
        case .text: return "doc.text"
        case .richText: return "doc.richtext"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .url: return "link"
        case .image: return "photo"
        case .file: return "doc"
        case .pdf: return "doc.richtext"
        case .color: return "eyedropper"
        case .unknown: return "doc.questionmark"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .text, .richText: return .blue
        case .code: return .purple
        case .url: return .green
        case .image: return .pink
        case .file, .pdf: return .orange
        case .color: return .yellow
        case .unknown: return .gray
        }
    }
}

// Color(hex:) extension removed - now defined in Color+Extensions.swift
