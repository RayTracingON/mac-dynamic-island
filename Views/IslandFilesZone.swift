import SwiftUI
import UniformTypeIdentifiers
import Combine

// MARK: - 文件架功能区 (Boring Shelf)
// 特性：拖拽暂存、点击打开、右键菜单

struct IslandFilesZone: View {
    @EnvironmentObject private var appState: AppState
    @State private var isTargeted = false
    @State private var isPulsing = false
    
    // Grid layout for files
    private let columns = [
        GridItem(.adaptive(minimum: 64, maximum: 80), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 💡 调试信息
            if !appState.trayItems.isEmpty {
                HStack {
                    Text("📊 Tray Items: \(appState.trayItems.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding(4)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(4)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
            }
            
            if appState.trayItems.isEmpty {
                // 空状态：引导用户拖拽
                emptyStateView
            } else {
                // 有文件：显示网格
                VStack(spacing: 8) {
                    // Header Status
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.blue)
                        Text("Shelf")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Text("\(appState.trayItems.count) items")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        
                        // Clear All Button
                        if !appState.trayItems.isEmpty {
                            Button("Clear") {
                                withAnimation {
                                    appState.trayItems.removeAll()
                                }
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundStyle(.red.opacity(0.8))
                            .padding(.leading, 8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                    
                    // File Grid
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(appState.trayItems) { item in
                                FileItemView(item: item) {
                                    removeItem(item)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // ✅ 确保整个区域可以接收事件
        .contentShape(Rectangle())
        // 🎉 Boring Notch 风格拖拽高亮 - 虚线边框 + 色彩变化
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    (isTargeted || appState.isGlobalDragActive)
                        ? Color.accentColor.opacity(0.9)
                        : Color.white.opacity(0.12),
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round,
                        dash: [10, 8]
                    )
                )
                .animation(.easeOut(duration: 0.25), value: isTargeted)
                .animation(.easeOut(duration: 0.25), value: appState.isGlobalDragActive)
                .padding(6)
        )
        // 🔴 内部色彩填充高亮
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    (isTargeted || appState.isGlobalDragActive)
                        ? Color.accentColor.opacity(isPulsing ? 0.15 : 0.10)
                        : Color.clear
                )
                .animation(
                    (isTargeted || appState.isGlobalDragActive)
                        ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                        : .default,
                    value: isPulsing
                )
        )
        // Drop Handler
        .onDrop(of: [.fileURL, .url, .utf8PlainText], isTargeted: $isTargeted) { providers in
            print("💥 [IslandFilesZone] onDrop triggered with \(providers.count) providers")
            
            // ✅ 关键修复：同步处理以确保立即执行
            Task { @MainActor in
                await handleDrop(providers)
            }
            
            // 返回 true 表示我们接受这个 drop
            return true
        }
        .onChange(of: isTargeted) { _, targeted in
            if targeted {
                isPulsing = true
                // 触觉反馈
                if SettingsDefaults.shared.get(SettingsDefaults.enableHaptics) {
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                }
            } else {
                isPulsing = false
            }
        }
        .onChange(of: appState.isGlobalDragActive) { _, active in
            if active {
                isPulsing = true
            } else {
                isPulsing = false
            }
        }
    }
    
    private var emptyStateView: some View {
        Button(action: selectFiles) {
            VStack(spacing: 16) {
                ZStack {
                    // 🌌 背景光晕效果
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    (isTargeted || appState.isGlobalDragActive) ? Color.accentColor.opacity(0.15) : Color.white.opacity(0.06),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect((isTargeted || appState.isGlobalDragActive) ? 1.1 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isTargeted)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: appState.isGlobalDragActive)
                    
                    // 📍 图标
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(
                            (isTargeted || appState.isGlobalDragActive)
                                ? LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.5), Color.white.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                        .symbolRenderingMode(.hierarchical)
                        .scaleEffect((isTargeted || appState.isGlobalDragActive) ? 1.15 : 1.0)
                        .offset(y: (isTargeted || appState.isGlobalDragActive) ? -2 : 0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTargeted)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: appState.isGlobalDragActive)
                }
                
                VStack(spacing: 6) {
                    Text((isTargeted || appState.isGlobalDragActive) ? "Drop files here" : "Ready for Files")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            (isTargeted || appState.isGlobalDragActive)
                                ? Color.accentColor
                                : Color.white.opacity(0.8)
                        )
                        .animation(.easeOut(duration: 0.2), value: isTargeted)
                        .animation(.easeOut(duration: 0.2), value: appState.isGlobalDragActive)
                    
                    Text((isTargeted || appState.isGlobalDragActive) ? "Release to save" : "Drag files or click to browse")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(
                            (isTargeted || appState.isGlobalDragActive)
                                ? Color.accentColor.opacity(0.7)
                                : Color.white.opacity(0.5)
                        )
                        .animation(.easeOut(duration: 0.2), value: isTargeted)
                        .animation(.easeOut(duration: 0.2), value: appState.isGlobalDragActive)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(IslandButtonStyle())
    }
    
    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        panel.begin { response in
            if response == .OK {
                Task { @MainActor in
                    for url in panel.urls {
                        let newItem = TrayStore.createTrayItem(from: url)
                        if !appState.trayItems.contains(where: { $0.filePath == newItem.filePath }) {
                            appState.trayItems.append(newItem)
                        }
                    }
                    // Haptic feedback
                    if SettingsDefaults.shared.get(SettingsDefaults.enableHaptics) {
                        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                    }
                }
            }
        }
    }
    
    private func removeItem(_ item: TrayItem) {
        if let index = appState.trayItems.firstIndex(where: { $0.id == item.id }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                _ = appState.trayItems.remove(at: index)
            }
        }
    }
    
    @MainActor
    private func handleDrop(_ providers: [NSItemProvider]) async {
        print("📊 [IslandFilesZone] handleDrop called with \(providers.count) providers")
        
        var urls: [URL] = []
        for provider in providers {
            print("🔍 [IslandFilesZone] Processing provider: \(provider)")
            
            // 尝试多种方式加载文件
            if let data = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) {
                if let url = data as? URL {
                    print("✅ [IslandFilesZone] Got URL directly: \(url.path)")
                    urls.append(url)
                } else if let data = data as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    print("✅ [IslandFilesZone] Got URL from data: \(url.path)")
                    urls.append(url)
                }
            }
        }
        
        print("📊 [IslandFilesZone] Total URLs extracted: \(urls.count)")
        
        if !urls.isEmpty {
            for url in urls {
                let newItem = TrayStore.createTrayItem(from: url)
                print("📦 [IslandFilesZone] Created TrayItem: \(newItem.displayName)")
                
                // 避免重复
                if !appState.trayItems.contains(where: { $0.filePath == newItem.filePath }) {
                    withAnimation(.spring()) {
                        appState.trayItems.append(newItem)
                    }
                    print("✅ [IslandFilesZone] Added to trayItems. Total count: \(appState.trayItems.count)")
                } else {
                    print("⚠️ [IslandFilesZone] File already exists in tray")
                }
            }
            
            // 📢 重要：保存到磁盘
            TrayStore.saveTrayItems(appState.trayItems)
            print("💾 [IslandFilesZone] Saved trayItems to disk")
            
            // 📢 强制刷新
            appState.objectWillChange.send()
            print("🔄 [IslandFilesZone] Forced UI refresh")
            
            // 触觉反馈
            if SettingsDefaults.shared.get(SettingsDefaults.enableHaptics) {
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            }
        } else {
            print("❌ [IslandFilesZone] No URLs were extracted from providers")
        }
    }
}

// MARK: - 单个文件视图

struct FileItemView: View {
    let item: TrayItem
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @State private var thumbnail: NSImage? = nil
    @State private var isThumbnailLoaded = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon / Thumbnail Area
            ZStack(alignment: .topTrailing) {
                if let image = thumbnail {
                    // 显示真实缩略图
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // 显示默认文件图标
                    Image(nsImage: item.getIcon())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                }
                
                // Delete Badge on Hover
                if isHovered {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white, .red)
                            .background(Circle().fill(.white).padding(2))
                    }
                    .buttonStyle(.plain)
                    .offset(x: 8, y: -8)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 48, height: 48)
            
            // File Name
            Text(item.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 26, alignment: .top)
        }
        .padding(8)
        // 🚫 移除不透明背景 - 仅使用非常淡的填充
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(isHovered ? 0.08 : 0.02))
        )
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        // 📦 拖出文件（关键：使用 contentsOf 以支持拖到其他应用）
        .onDrag {
            print("👋 [FileItemView] Starting drag for: \(item.displayName)")
            
            let fileURL = URL(fileURLWithPath: item.filePath)
            
            // 检查文件是否存在
            guard FileManager.default.fileExists(atPath: item.filePath) else {
                print("❌ [FileItemView] File doesn't exist: \(item.filePath)")
                return NSItemProvider()
            }
            
            // ✅ 关键：使用 contentsOf 以提供实际文件内容
            guard let provider = NSItemProvider(contentsOf: fileURL) else {
                print("❌ [FileItemView] Failed to create NSItemProvider")
                return NSItemProvider()
            }
            
            provider.suggestedName = item.displayName
            print("✅ [FileItemView] Created provider with suggested name: \(item.displayName)")
            
            return provider
        } preview: {
            // 🎨 拖拽时的预览图
            HStack(spacing: 8) {
                Image(nsImage: item.getIcon())
                    .resizable()
                    .frame(width: 32, height: 32)
                Text(item.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
        }
        // 双击打开
        .onTapGesture(count: 2) {
            NSWorkspace.shared.open(URL(fileURLWithPath: item.filePath))
        }
        // 加载缩略图
        .onAppear {
            loadThumbnail()
        }
        // 右键菜单
        .contextMenu {
            Button("Open") {
                NSWorkspace.shared.open(URL(fileURLWithPath: item.filePath))
            }
            
            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.filePath)])
            }
            
            Divider()
            
            Button("Share via AirDrop") {
                ShareService.shared.shareViaAirDrop(urls: [URL(fileURLWithPath: item.filePath)])
            }
            
            Button("Share...") {
                // 由于 ShareService 需要 View 引用，这里我们在后台调用或使用通用分享
                // 暂时使用简单的 share 逻辑，实际可能需要 ShareServicePicker
                ShareService.shared.share(urls: [URL(fileURLWithPath: item.filePath)])
            }
            
            Divider()
            
            Button("Remove from Shelf", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private func loadThumbnail() {
        guard !isThumbnailLoaded else { return }
        
        // 异步加载高质量缩略图
        ThumbnailService.shared.generateThumbnail(for: URL(fileURLWithPath: item.filePath)) { image in
            if let image = image {
                withAnimation(.easeIn(duration: 0.2)) {
                    self.thumbnail = image
                    self.isThumbnailLoaded = true
                }
            }
        }
    }
}
