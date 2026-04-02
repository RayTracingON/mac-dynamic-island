//
//  ClipboardCompactReelView.swift
//  Mac灵动岛
//
//  Compact overlay summary (used in overlay compact mode)
//  Shows status only when overlay is compact
//

import SwiftUI
import AppKit

struct ClipboardCompactReelView: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    @EnvironmentObject var appState: AppState
    
    private var currentMode: IslandSizingPolicy.WidthMode {
        appState.currentWidthMode
    }
    
    /// CRITICAL: Show full panel when overlay is expanded
    /// Always show full panel when expanded mode, regardless of width
    private var isFullyExpanded: Bool {
        appState.overlayMode == .expanded
    }
    
    var body: some View {
        Group {
            if isFullyExpanded {
                // Full interactive panel - only when explicitly expanded
                SystemGradeClipboardPanel()
            } else {
                // All compact states: simple summary that invites clicking
                CompactSummaryView()
            }
        }
        .clipboardKeyRouter(hubStore: hubStore, appState: appState)
        .onAppear {
            if hubStore.selectedItemID == nil, let first = hubStore.items.first {
                hubStore.selectItem(first.id)
            }
        }
    }
}

// MARK: - Compact Summary View
// DESIGN: All compact states show the SAME simple summary.
// This establishes a clear mental model: compact = preview, click = expand.
// No interactive elements in compact mode - just information display.

private struct CompactSummaryView: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    @EnvironmentObject var appState: AppState
    
    private var itemCount: Int { hubStore.items.count }
    private var latestItem: IslandClipItem? { hubStore.items.first }
    
    var body: some View {
        HStack(spacing: 12) {
            // Left: Status indicator
            statusIndicator
            
            // Center: Content preview
            contentPreview
            
            Spacer()
            
            // Right: Item count badge (if multiple items)
            if itemCount > 1 {
                itemCountBadge
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Entire compact view is tappable - clicking expands
        .contentShape(Rectangle())
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private var statusIndicator: some View {
        Circle()
            .fill(itemCount > 0 ? Color.white.opacity(0.4) : Color.white.opacity(0.2))
            .frame(width: 6, height: 6)
    }
    
    @ViewBuilder
    private var contentPreview: some View {
        if let item = latestItem {
            HStack(spacing: 8) {
                // Source app icon
                Image(nsImage: item.sourceAppIcon())
                    .resizable()
                    .frame(width: 16, height: 16)
                    .cornerRadius(3)
                
                // Preview text
                Text(item.previewText)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        } else {
            Text("Clipboard empty")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.4))
        }
    }
    
    @ViewBuilder
    private var itemCountBadge: some View {
        Text("\(itemCount)")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white.opacity(0.6))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.12))
            )
    }
}

// MARK: - System-Grade Panel (Expanded)
// PUBLIC: Used by NotchOverlayView for expanded clipboard display

struct SystemGradeClipboardPanel: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // ZONE 1: Command Strip (always visible, never empty)
            CommandStrip()
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                #if DEBUG
                .debugInteractionOverlay(label: "Z1:CMD", color: .green)
                #endif
            
            Divider()
                .opacity(IslandStyleTokens.separatorOpacity)
            
            // ZONE 3: Pinned Section (if exists)
            if !hubStore.pinnedItems.isEmpty {
                PinnedWorkingMemory()
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    #if DEBUG
                    .debugInteractionOverlay(label: "Z3:PIN", color: .purple)
                    #endif
            }
            
            // ZONE 2: Content Grid (primary workspace)
            ContentGrid()
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                #if DEBUG
                .debugInteractionOverlay(label: "Z2:GRID", color: .blue)
                #endif
        }
        #if DEBUG
        .overlay(alignment: .topTrailing) {
            // Global interaction diagnostic indicator
            Text("🔍 DEBUG: Hit-test mode")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.yellow)
                .padding(4)
                .background(Color.black.opacity(0.6))
                .cornerRadius(4)
                .padding(8)
        }
        #endif
    }
}

// MARK: - ZONE 1: Command Strip

private struct CommandStrip: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    @FocusState private var searchFocused: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            // Search field - functional, instant (constrained width to leave room for filters)
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Search", text: $hubStore.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .focused($searchFocused)
                
                if !hubStore.searchQuery.isEmpty {
                    Button(action: {
                        hubStore.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: 140)  // Constrain search field to leave room for filters
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
            )
            .onKeyPress(.escape) {
                hubStore.searchQuery = ""
                searchFocused = false
                return .handled
            }
            
            // Type filters - compact with adequate spacing
            HStack(spacing: 4) {
                ForEach([SearchEngine.ContentFilter.all, .text, .links, .images], id: \.self) { filter in
                    TypeFilterPill(filter: filter)
                }
            }
            
            Spacer(minLength: 8)
            
            // Status indicators - more compact
            HStack(spacing: 8) {
                StatusIndicator(
                    icon: "doc.on.clipboard",
                    count: hubStore.totalItemCount,
                    label: "items"
                )
                
                if hubStore.pinnedItems.count > 0 {
                    StatusIndicator(
                        icon: "pin.fill",
                        count: hubStore.pinnedItems.count,
                        label: "pinned"
                    )
                }
            }
        }
    }
}

private struct TypeFilterPill: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    let filter: SearchEngine.ContentFilter
    
    private var isSelected: Bool {
        hubStore.currentFilter == filter
    }
    
    private var count: Int {
        switch filter {
        case .all: return hubStore.totalItemCount
        case .text: return hubStore.textItemCount
        case .images: return hubStore.imageItemCount
        case .links: return hubStore.items.filter { $0.contentType == .url }.count
        default: return 0
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(IslandStyleTokens.hoverAnimation) {
                hubStore.setFilter(filter)
            }
        }) {
            HStack(spacing: 4) {
                Text(filter.displayName)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                
                if count > 0 && filter != .all {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            .foregroundColor(isSelected ? .primary : .secondary.opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
    }
}

private struct StatusIndicator: View {
    let icon: String
    let count: Int
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("\(count)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - ZONE 3: Pinned Working Memory

private struct PinnedWorkingMemory: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "pin.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text("Pinned")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(hubStore.pinnedItems.prefix(6)) { item in
                    PinnedClipCard(item: item)
                }
            }
        }
        .padding(.vertical, 12)
    }
}

private struct PinnedClipCard: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    let item: IslandClipItem
    
    @State private var isHovered = false
    
    var body: some View {
        let cardBackground = RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.white.opacity(0.03))
            .allowsHitTesting(false)
            
        let cardStrokeSize = IslandStyleTokens.surfaceStrokeWidth
        let cardStroke = RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    Color.white.opacity(0.10), 
                    lineWidth: cardStrokeSize
                )
                .allowsHitTesting(false)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(nsImage: item.sourceAppIcon())
                    .resizable()
                    .frame(width: 14, height: 14)
                    .cornerRadius(3)
                
                Spacer()
                
                if !isHovered {
                    ContentTypeBadge(type: item.contentType)
                }
            }
            
            Text(item.previewText)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 0)
            
            HStack(spacing: 4) {
                Text(item.relativeTimeString)
                    .font(.system(size: 8, weight: .regular))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if isHovered {
                    HoverActionBar(
                        item: item,
                        onCopy: { hubStore.copyToClipboard(item) },
                        onUnpin: { hubStore.togglePin(for: item) },
                        onDelete: { hubStore.removeItem(item) },
                        compact: true
                    )
                }
            }
        }
        .padding(10)
        .frame(height: 90)
        .background(cardBackground)
        .overlay(cardStroke)
        .onHover { hovering in
            withAnimation(IslandStyleTokens.hoverAnimation) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            hubStore.copyToClipboard(item)
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        }
    }
}

// MARK: - ZONE 2: Content Grid

private struct ContentGrid: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    
    private var displayItems: [IslandClipItem] {
        hubStore.displayItems.filter { !$0.isPinned }
    }
    
    var body: some View {
        if displayItems.isEmpty {
            EmptyContentState()
        } else {
            // HARD CONTRACT: 2×3 grid = EXACTLY 6 items visible
            // NO SCROLLING in Peek state - all 6 items must be visible at once
            let columns = Array(repeating: GridItem(.flexible(), spacing: IslandLayoutConstants.gridSpacing),
                                count: IslandLayoutConstants.peekGridColumns)
            
            // MANDATORY: Always show exactly 6 items (use .prefix to enforce)
            let visibleItems = Array(displayItems.prefix(IslandLayoutConstants.peekVisibleItemCount))
            
            // FIXED GRID: No ScrollView, no adaptive sizing
            // Grid height = (cardHeight × 2) + (spacing × 1) = 110×2 + 10 = 230pt
            LazyVGrid(columns: columns, spacing: IslandLayoutConstants.gridSpacing) {
                ForEach(visibleItems) { item in
                    ClipboardGridCard(item: item)
                }
            }
            .frame(height: IslandLayoutConstants.peekGridMaxHeight)
            #if DEBUG
            .onAppear {
                // Validate 6-item contract
                print("📊 GRID: Showing \(visibleItems.count) items in \(IslandLayoutConstants.peekGridColumns) columns")
                IslandLayoutConstants.validatePeekLayout(
                    visibleItemCount: visibleItems.count,
                    columns: IslandLayoutConstants.peekGridColumns
                )
            }
            #endif
        }
    }
}

private struct ClipboardGridCard: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    let item: IslandClipItem
    
    @State private var isHovered = false
    
    private var isSelected: Bool {
        hubStore.selectedItemID == item.id
    }
    
    var body: some View {
        let cardCorner = IslandLayoutConstants.gridCardCornerRadius
        let bgFill = Color.white.opacity(0.05) // simplified material
        
        let cardBg = RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                .fill(bgFill)
                .allowsHitTesting(false)
        
        return VStack(alignment: .leading, spacing: 8) {
            // Header: App icon + Type badge
            HStack(spacing: 6) {
                Image(nsImage: item.sourceAppIcon())
                    .resizable()
                    .frame(width: 16, height: 16)
                    .cornerRadius(3)
                
                Spacer()
                
                if !isHovered {
                    ContentTypeBadge(type: item.contentType)
                }
            }
            
            // Content preview
            Group {
                switch item.contentType {
                case .url:
                    URLPreviewContent(item: item)
                case .image:
                    ImagePreviewContent(item: item)
                default:
                    TextPreviewContent(item: item)
                }
            }
            
            Spacer(minLength: 0)
            
            // Metadata row
            HStack(spacing: 6) {
                Text(item.relativeTimeString)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(.secondary)
                
                if item.contentType != .url && item.contentType != .image {
                    Text("·")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    
                    Text(item.sizeInfo)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isHovered {
                    HoverActionBar(
                        item: item,
                        onCopy: { hubStore.copyToClipboard(item) },
                        onUnpin: { hubStore.togglePin(for: item) },
                        onDelete: { hubStore.removeItem(item) },
                        compact: false
                    )
                } else if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 5, height: 5)
                }
            }
        }
        // LAYOUT GUARD: Card dimensions from IslandLayoutConstants
        .padding(IslandLayoutConstants.gridCardPadding)
        .frame(height: IslandLayoutConstants.gridCardHeight)
        .background(cardBg)
        .overlay(
            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                .strokeBorder(
                    isSelected ? Color.accentColor.opacity(0.5) : (isHovered ? Color.white.opacity(0.1) : Color.clear),
                    lineWidth: isSelected ? 1.5 : 1
                )
                .allowsHitTesting(false)  // CRITICAL: Decorative only
        )
        .shadow(
            color: isSelected ? Color.accentColor.opacity(0.1) : .black.opacity(0.04),
            radius: isSelected ? 4 : 2,
            x: 0,
            y: 1
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.86)) {
                hubStore.selectItem(item.id)
            }
        }
    }
}

// MARK: - Content Type Badge

private struct ContentTypeBadge: View {
    let type: ClipboardItemV2.ContentType
    
    var body: some View {
        Text(badgeText)
            .font(.system(size: 7, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(badgeColor)
            )
    }
    
    private var badgeText: String {
        switch type {
        case .text: return "TXT"
        case .richText: return "RTF"
        case .code: return "CODE"
        case .url: return "LINK"
        case .image: return "IMG"
        case .file: return "FILE"
        case .pdf: return "PDF"
        case .color: return "CLR"
        case .unknown: return "?"
        }
    }
    
    private var badgeColor: Color {
        Color(nsColor: type.badgeColor).opacity(0.7)
    }
}

// MARK: - Content Previews

private struct TextPreviewContent: View {
    let item: IslandClipItem
    
    var body: some View {
        Text(item.previewText)
            .font(.system(size: 10, weight: .regular))
            .foregroundColor(.primary)
            .lineLimit(3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct URLPreviewContent: View {
    let item: IslandClipItem
    
    private var host: String {
        if let urlString = item.urlString,
           let url = URL(string: urlString),
           let host = url.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        return ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !host.isEmpty {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green.opacity(0.5))
                        .frame(width: 5, height: 5)
                    
                    Text(host)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            }
            
            Text(item.urlString ?? "")
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ImagePreviewContent: View {
    let item: IslandClipItem
    
    var body: some View {
        if let imageData = item.imageData,
           let nsImage = NSImage(data: imageData) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: 50)
                .clipped()
                .cornerRadius(6)
        } else {
            HStack {
                Image(systemName: "photo")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("[Image]")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: 50)
        }
    }
}

// MARK: - Hover Action Bar

private struct HoverActionBar: View {
    let item: IslandClipItem
    let onCopy: () -> Void
    let onUnpin: () -> Void
    let onDelete: () -> Void
    let compact: Bool
    
    var body: some View {
        HStack(spacing: compact ? 4 : 6) {
            ActionButton(icon: "doc.on.doc", action: onCopy)
            ActionButton(icon: item.isPinned ? "pin.slash" : "pin", action: onUnpin)
            ActionButton(icon: "trash", action: onDelete, isDestructive: true)
        }
    }
}

private struct ActionButton: View {
    let icon: String
    let action: () -> Void
    var isDestructive: Bool = false
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(isDestructive ? .red.opacity(0.7) : .secondary)
                .frame(width: 18, height: 18)
                .background(
                    Circle()
                        .fill(.regularMaterial)
                        .opacity(isHovered ? 0.8 : 1.0)
                        // HIT-TESTING FIX: Background is decorative, button handles all events
                        .allowsHitTesting(false)
                )
        }
        .buttonStyle(.plain)
        // CRITICAL: No gesture conflicts - use hover for feedback instead
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Empty State

private struct EmptyContentState: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    
    var body: some View {
        VStack(spacing: 16) {
            if hubStore.searchQuery.isEmpty {
                // True empty state
                VStack(spacing: 12) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 32, weight: .thin))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No clipboard history")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Copy text, links, or images\nThey'll appear here instantly")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 32)
            } else {
                // Search empty
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28, weight: .thin))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No results for \"\(hubStore.searchQuery)\"")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Button("Clear search") {
                        hubStore.searchQuery = ""
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.vertical, 32)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Compact Peek Mode

private struct CompactPeekMode: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(hubStore.displayItems.prefix(10)) { item in
                        CompactPeekCard(item: item)
                            .id(item.id)
                            .onTapGesture {
                                appState.activateOverlay(reason: .userExpanded)
                            }
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 64)
            .mask(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.05),
                        .init(color: .black, location: 0.95),
                        .init(color: .clear, location: 1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .onChange(of: hubStore.selectedItemID) { _, newID in
                if let newID = newID {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.86)) {
                        proxy.scrollTo(newID, anchor: .center)
                    }
                }
            }
        }
    }
}

private struct CompactPeekCard: View {
    let item: IslandClipItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(nsImage: item.sourceAppIcon())
                    .resizable()
                    .frame(width: 12, height: 12)
                    .cornerRadius(3)
                
                Spacer()
                
                ContentTypeBadge(type: item.contentType)
            }
            
            Text(item.previewText)
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Text(item.relativeTimeString)
                .font(.system(size: 7, weight: .regular))
                .foregroundColor(.secondary)
        }
        .padding(8)
        .frame(width: 90, height: 64)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}
