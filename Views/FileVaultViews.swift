import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - File Vault Panel View
/// Apple-grade file vault panel with native macOS styling
struct FileVaultPanelView: View {
    @EnvironmentObject private var fileVault: FileVaultStore
    @EnvironmentObject private var appState: AppState
    let onClose: () -> Void
    
    @State private var showClearConfirmation = false
    @State private var toastMessage: String? = nil
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            FileVaultHeader(
                fileCount: fileVault.fileCount,
                pinnedCount: fileVault.pinnedCount,
                onClearAll: {
                    if fileVault.unpinnedCount > 0 {
                        showClearConfirmation = true
                    }
                }
            )
            .padding(.bottom, 8)
            
            // Content
            if fileVault.isEmpty {
                FileVaultEmptyState()
            } else {
                FileVaultList(onShowToast: { message in
                    showToast(message)
                })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .focused($isFocused)
        .onAppear {
            isFocused = true
        }
        .onKeyPress(keys: [.upArrow]) { _ in
            fileVault.selectPrevious()
            return .handled
        }
        .onKeyPress(keys: [.downArrow]) { _ in
            fileVault.selectNext()
            return .handled
        }
        .onKeyPress(keys: [.return]) { _ in
            if fileVault.openSelected() {
                showToast("Opened")
            }
            return .handled
        }
        .onKeyPress(keys: [.delete]) { _ in
            if fileVault.selectedFileID != nil {
                fileVault.removeSelected()
                showToast("Removed")
            }
            return .handled
        }
        // FIXED: Add ESC key handling at view level for reliable close path
        .onKeyPress(keys: [.escape]) { _ in
            // If showing confirmation dialog, cancel it first
            if showClearConfirmation {
                showClearConfirmation = false
                return .handled
            }
            // Otherwise close the overlay
            onClose()
            return .handled
        }
        .overlay(alignment: .bottom) {
            // Clear confirmation toast
            if showClearConfirmation {
                ClearConfirmationToast(
                    count: fileVault.unpinnedCount,
                    onConfirm: {
                        fileVault.clearUnpinned()
                        showClearConfirmation = false
                        showToast("Cleared \(fileVault.unpinnedCount) file(s)")
                    },
                    onCancel: {
                        showClearConfirmation = false
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            }
            
            // General toast
            if let message = toastMessage {
                ToastView(message: message)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showClearConfirmation)
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: toastMessage != nil)
    }
    
    private func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }
}

// MARK: - File Vault Header

struct FileVaultHeader: View {
    let fileCount: Int
    let pinnedCount: Int
    let onClearAll: () -> Void
    
    @State private var isHoveringClear = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Title with count
            HStack(spacing: 4) {
                Text("Files")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
                
                if fileCount > 0 {
                    Text("\(fileCount)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                        )
                }
            }
            
            Spacer()
            
            // Clear button (only visible when there are unpinned files)
            if fileCount > pinnedCount {
                Button(action: onClearAll) {
                    HStack(spacing: 3) {
                        Image(systemName: "trash")
                            .font(.system(size: 8, weight: .medium))
                        
                        if isHoveringClear {
                            Text("Clear")
                                .font(.system(size: 9, weight: .medium))
                        }
                    }
                    .foregroundColor(.white.opacity(isHoveringClear ? 0.5 : 0.3))
                    .padding(.horizontal, isHoveringClear ? 6 : 4)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.white.opacity(isHoveringClear ? 0.08 : 0))
                    )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.15)) {
                        isHoveringClear = hovering
                    }
                }
            }
        }
    }
}

// MARK: - File Vault Empty State

struct FileVaultEmptyState: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 10) {
            // Animated folder icon
            ZStack {
                Image(systemName: "folder")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.white.opacity(0.2))
                
                Image(systemName: "arrow.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.25))
                    .offset(y: isAnimating ? 2 : -2)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
            
            Text("Drop files here")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.white.opacity(0.4))
            
            Text("Quick access from the island")
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(.white.opacity(0.25))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - File Vault List

struct FileVaultList: View {
    @EnvironmentObject private var fileVault: FileVaultStore
    let onShowToast: (String) -> Void
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(fileVault.groupedFiles, id: \.kind) { group in
                        // Collapsible section header (only show if multiple groups)
                        if fileVault.groupedFiles.count > 1 {
                            FileVaultSectionHeader(
                                kind: group.kind,
                                count: group.files.count,
                                isCollapsed: fileVault.isSectionCollapsed(group.kind),
                                onToggle: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        fileVault.toggleSectionCollapsed(group.kind)
                                    }
                                }
                            )
                            .padding(.top, group.kind == fileVault.groupedFiles.first?.kind ? 0 : 8)
                        }
                        
                        // Files in this group (with collapse animation)
                        if !fileVault.isSectionCollapsed(group.kind) {
                            ForEach(group.files) { file in
                                FileVaultRow(
                                    vaultFile: file,
                                    isSelected: fileVault.selectedFileID == file.id,
                                    onShowToast: onShowToast
                                )
                                .id(file.id)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                    removal: .opacity
                                ))
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: 180)
            .onChange(of: fileVault.selectedFileID) { _, newID in
                if let id = newID {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }
}

// MARK: - Section Header (Collapsible)

struct FileVaultSectionHeader: View {
    let kind: FileKind
    let count: Int
    let isCollapsed: Bool
    let onToggle: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 4) {
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35))
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                
                // Section name
                Text(kind.displayName)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(isHovered ? 0.55 : 0.35))
                
                // Count badge
                Text("\(count)")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.25))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                    )
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - File Vault Row
/// Individual file row with SANDWICH LAYER architecture
/// LAYER 1 (Bottom): Draggable content with file info
/// LAYER 2 (Top): Isolated delete button with high-priority gesture
struct FileVaultRow: View {
    @EnvironmentObject private var fileVault: FileVaultStore
    @EnvironmentObject private var appState: AppState
    let vaultFile: FileVaultStore.VaultFile
    let isSelected: Bool
    let onShowToast: (String) -> Void
    
    @State private var isHovered = false
    @State private var isDeleting = false
    @State private var deleteButtonHovered = false
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.25)
        } else if isHovered {
            return Color.white.opacity(0.06)
        }
        return Color.clear
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            rowSurfaceContent
            actionButtonsOverlay
        }
        .opacity(isDeleting ? 0.0 : 1.0)
        .scaleEffect(isDeleting ? 0.8 : 1.0)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            menuContent
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(vaultFile.fileName), saved \(vaultFile.formattedTime)\(vaultFile.isMissing ? ", missing" : "")\(vaultFile.isPinned ? ", pinned" : "")")
        .accessibilityHint(vaultFile.isMissing ? "File is missing" : "Double-click to open, drag to copy")
        .animation(.easeOut(duration: 0.1), value: isHovered)
        .animation(.easeOut(duration: 0.1), value: isSelected)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isDeleting)
    }
    
    @ViewBuilder
    private var rowSurfaceContent: some View {
        HStack(spacing: 10) {
            // File icon
            Image(nsImage: vaultFile.icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 24, height: 24)
                .opacity(vaultFile.isMissing ? 0.4 : 1.0)
                .overlay(alignment: .bottomTrailing) {
                    if vaultFile.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(2)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .offset(x: 2, y: 2)
                    }
                }
            
            // File info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(vaultFile.fileName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(vaultFile.isMissing ? 0.45 : 0.85))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    if vaultFile.isMissing {
                        Text("Missing")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.orange.opacity(0.15)))
                    }
                }
                
                HStack(spacing: 4) {
                    Text(vaultFile.formattedTime)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(.white.opacity(0.4))
                    
                    if let size = vaultFile.fileSize {
                        Text("·")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.25))
                        Text(size)
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            
            Spacer()
            
            // Reserve space for buttons to prevent layout shift
            if isHovered || isSelected {
                Color.clear.frame(width: 52, height: 24)
            }
        }
        .contentShape(Rectangle()) // Make entire row hit-testable
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(backgroundColor)
        )
        // ✅ FIX DRAG-OUT: Use NSItemProvider(contentsOf:) with file URL
        .onDrag {
            appState.isDraggingOutbound = true
            
            // Must return valid file URL for drag-out to work
            guard let url = vaultFile.resolvedURL, vaultFile.fileExists else {
                DispatchQueue.main.async { appState.isDraggingOutbound = false }
                return NSItemProvider()
            }
            
            // ✅ CRITICAL: Use contentsOf to provide actual file
            let provider = NSItemProvider(contentsOf: url) ?? NSItemProvider()
            provider.suggestedName = vaultFile.fileName
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if appState.isDraggingOutbound { 
                    appState.isDraggingOutbound = false 
                }
            }
            return provider
        } preview: {
            HStack(spacing: 6) {
                Image(nsImage: vaultFile.icon)
                    .resizable()
                    .frame(width: 20, height: 20)
                Text(vaultFile.fileName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(.regularMaterial))
        }
        // Single-click to select
        .onTapGesture {
            fileVault.selectedFileID = vaultFile.id
        }
        // Double-click to open
        .onTapGesture(count: 2) {
            if fileVault.openFile(id: vaultFile.id) {
                onShowToast("Opened")
            }
        }
    }
    
    @ViewBuilder
    private var actionButtonsOverlay: some View {
        if isHovered || isSelected {
            HStack(spacing: 4) {
                // ✅ FIX GESTURE: Delete button with high-priority tap
                Button(action: {
                    deleteFile()
                }) {
                    Image(systemName: deleteButtonHovered ? "trash.circle.fill" : "trash")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(deleteButtonHovered ? .red : .white.opacity(0.5))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)
                // ✅ High-priority gesture to override underlying drag
                .highPriorityGesture(
                    TapGesture().onEnded {
                        deleteFile()
                    }
                )
                .onHover { hovering in
                    deleteButtonHovered = hovering
                }
                .help("Delete")
                
                // More menu
                Menu {
                    menuContent
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 20, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                        )
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }
            .padding(.trailing, 12)
            .zIndex(100) // Ensure buttons are above drag layer
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
        }
    }
    
    /// Delete file with animation
    private func deleteFile() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            isDeleting = true
        }
        
        // Delay actual removal to let animation play
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            fileVault.removeFile(id: vaultFile.id)
            onShowToast("Removed")
        }
    }
    
    @ViewBuilder
    private var menuContent: some View {
        Button(action: {
            if fileVault.openFile(id: vaultFile.id) {
                onShowToast("Opened")
            }
        }) {
            Label("Open", systemImage: "arrow.up.forward.app")
        }
        .disabled(vaultFile.isMissing)
        
        Button(action: {
            fileVault.revealInFinder(id: vaultFile.id)
        }) {
            Label("Reveal in Finder", systemImage: "folder")
        }
        .disabled(vaultFile.isMissing)
        
        Button(action: {
            fileVault.copyPath(id: vaultFile.id)
            onShowToast("Path copied")
        }) {
            Label("Copy Path", systemImage: "doc.on.doc")
        }
        
        Divider()
        
        Button(action: {
            fileVault.togglePin(id: vaultFile.id)
            onShowToast(vaultFile.isPinned ? "Unpinned" : "Pinned")
        }) {
            Label(vaultFile.isPinned ? "Unpin" : "Pin", systemImage: vaultFile.isPinned ? "pin.slash" : "pin")
        }
        
        Divider()
        
        Button(role: .destructive, action: {
            fileVault.removeFile(id: vaultFile.id)
            onShowToast("Removed")
        }) {
            Label("Remove", systemImage: "trash")
        }
    }
}

// MARK: - Drop Highlight Overlay
/// Apple-grade drop target visualization
struct FileDropHighlightView: View {
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Outer glow
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.6), Color.accentColor.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 0)
            
            // Background tint
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.accentColor.opacity(isPulsing ? 0.12 : 0.08))
            
            // Drop hint content
            VStack(spacing: 6) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.accentColor)
                    .scaleEffect(isPulsing ? 1.05 : 1.0)
                
                Text("Drop to save")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentColor)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.75))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            )
            .padding(.bottom, 8)
    }
}

// MARK: - Clear Confirmation Toast

struct ClearConfirmationToast: View {
    let count: Int
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Text("Clear \(count) file\(count == 1 ? "" : "s")?")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 6) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                
                Button(action: onConfirm) {
                    Text("Clear")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.red.opacity(0.8))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(white: 0.15))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .padding(.bottom, 8)
    }
}

// MARK: - Drop Result Toast

struct DropResultToast: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.green)
            
            Text(count == 1 ? "Saved 1 file" : "Saved \(count) files")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.75))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
    }
}
