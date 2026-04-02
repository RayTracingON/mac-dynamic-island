import Foundation
import SwiftUI
import Combine
import OSLog
import AppKit
import ApplicationServices

@MainActor
final class AppState: ObservableObject {
    let settings = AppSettings.shared
    let settingsStore = SettingsDefaults.shared
    
    // PREMIUM SERVICES (Consolidated & Unique)
    let clipVault = IslandClipVault()
    var clipboardHub: ClipboardHubStore { clipVault }
    private(set) var clipManager: ClipboardManager?
    
    // OLD/DEPRECATED
    let clipboardHistory = ClipboardHistoryStore()
    // let clipboardHub = ClipboardHubStore() // REMOVED: Migrated to clipVault
    
    let fileVault = FileVaultStore()
    let zone3Manager = Zone3StateManager.shared
    let scratchpad = ScratchpadStore.shared
    
    @Published var currentUserStatus: UserStatus = .default
    @Published var isOverlayVisible: Bool = true
    @Published var visibilityReason: OverlayVisibilityReason = .none
    @Published var interactionState: IslandInteractionState = .idle
    @Published var overlayMode: OverlayMode = .compact {
        didSet { resetAutoCloseTimer() }
    }
    @Published var overlayIntent: OverlayIntent = .none
    @Published var currentSection: IslandSection = .music {
        didSet { resetAutoCloseTimer() }
    }
    @Published var lastCopiedAt: Date? = nil
    @Published var trayItems: [TrayItem] = []
    @Published var isDraggingOutbound: Bool = false
    @Published var isDraggingOver: Bool = false
    @Published var isNearIsland: Bool = false
    @Published var isGlobalDragActive: Bool = false // 全局拖拽检测状态
    
    // DEBUG METRICS
    @Published var lastEventDescription: String = "None"
    @Published var lastEventTimestamp: String = "--:--:--"
    
    // CUSTOMIZATION: Resolved from settingsStore
    var islandBackgroundColor: Color {
        settingsStore.resolveBackgroundColor()
    }
    
    private var settingsCancellable: AnyCancellable?
    private var autoCloseTimer: Timer?
    
    init() {
        // Sync setting changes to AppState triggers
        settingsCancellable = settingsStore.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        
        // Initialize services
        self.clipVault.loadFromDisk()
        let manager = ClipboardManager(vault: self.clipVault)
        self.clipManager = manager
        manager.start()
        
        // Load tray items
        self.trayItems = TrayStore.loadTrayItems()
        
        // Global Drag Vicinity Observers
        NotificationCenter.default.addObserver(forName: .dragEnteredIslandVicinity, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.isNearIsland = true
                self.isDraggingOver = true
                
                // Proactive magnetic expansion logic (Boring Notch style)
                // We don't auto-expand to full size immediately, just set state for visual feedback first
                // Expansion happens if hover persists or drop occurs (handled by DropDelegate)
            }
        }
        
        NotificationCenter.default.addObserver(forName: .dragExitedIslandVicinity, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.isNearIsland = false
                self.isDraggingOver = false
            }
        }
        
        // 启动全局拖拽检测器（Boring Notch 风格）
        setupGlobalDragDetector()
    }
    
    func resetAutoCloseTimer() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        
        guard overlayMode == .expanded else { return }
        guard settingsStore.get(SettingsDefaults.autoCloseEnabled) else { return }
        
        let timeout = settingsStore.get(SettingsDefaults.autoCloseTimeout)
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.deactivateOverlay()
            }
        }
    }
    
    // UI Sizing Mode
    var currentWidthMode: IslandSizingPolicy.WidthMode {
        IslandSizingPolicy.determineMode(
            itemCount: clipVault.items.count,
            isUserExpanded: overlayMode == .expanded,
            isClipboardClosed: interactionState == .idle
        )
    }
    
    // ADVANCED STATE (boringNotch compatibility)
    enum Payload: Equatable {
        case none
        case file(URL)
        case url(URL)
        case text(String)
        case clipboard(String)
    }
    
    @Published var payload: Payload = .none
    @Published var hint: String? = nil
    
    // PERMISSIONS & ONBOARDING
    @Published var isAXAuthorized: Bool = AXIsProcessTrusted()
    @Published var isOnboardingPresented: Bool = false
    @Published var isPositionLocked: Bool = true
    @Published var isMoveModeEnabled: Bool = false
    var isDraggable: Bool { isMoveModeEnabled || !isPositionLocked }
    
    func requestAXPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    func refreshAXStatus() {
        isAXAuthorized = AXIsProcessTrusted()
    }
    
    func togglePositionLock() {
        isPositionLocked.toggle()
        logEvent("Position lock: \(isPositionLocked)")
    }
    
    func toggleMoveMode() {
        isMoveModeEnabled.toggle()
        logEvent("Move mode: \(isMoveModeEnabled)")
    }
    
    // MARK: - Localized Properties
    
    var localizedTitle: String {
        if let h = hint { return h }
        switch payload {
        case .none: return L("overlay.title_drop_here")
        case .file: return L("overlay.title_file")
        case .url: return L("overlay.title_url")
        case .text: return L("overlay.title_text")
        case .clipboard: return L("overlay.title_clipboard")
        }
    }
    
    var localizedSubtitle: String {
        switch payload {
        case .none: return L("overlay.subtitle_supports")
        case .file: return L("overlay.subtitle_file_received")
        case .url: return L("overlay.subtitle_url_received")
        case .text: return L("overlay.subtitle_text_received")
        case .clipboard: return L("overlay.subtitle_clipboard_updated")
        }
    }
    
    var payloadSummary: String {
        switch payload {
        case .none: return ""
        case .file(let url): return url.lastPathComponent
        case .url(let url): return url.absoluteString
        case .text(let text): return text
        case .clipboard(let text): return text
        }
    }
    
    private func L(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
    // ENUMS & STRUCTS
    struct UserStatus: Identifiable, Equatable {
        let id = UUID()
        let icon: String; let text: String; let color: Color
        static let `default` = UserStatus(icon: "😎", text: "Mac 灵动岛", color: .white)
    }
    
    enum IslandSection: String, CaseIterable {
        case music, clipboard, files, calendar, zone3
        var displayName: String { 
             switch self { 
             case .music: return "Music"
             case .clipboard: return "Clipboard"
             case .files: return "Files"
             case .calendar: return "Calendar"
             case .zone3: return "Zone"
             } 
        }
        var iconName: String { 
             switch self { 
             case .music: return "music.note"
             case .clipboard: return "doc.on.clipboard"
             case .files: return "folder"
             case .calendar: return "calendar"
             case .zone3: return "briefcase"
             } 
        }
    }
    
    enum OverlayMode { case compact, expanded }
    enum OverlayIntent { case none, userRequestedOpen, userRequestedClose }
    
    
    // HELPER METHODS
    func showOverlay(reason: OverlayVisibilityReason = .userExpanded) {
        visibilityReason = reason; isOverlayVisible = true
    }
    func hideOverlay() { 
        visibilityReason = .none; isOverlayVisible = false; overlayMode = .compact 
    }
    func activateOverlay(reason: OverlayVisibilityReason = .userExpanded) {
        interactionState = .active; overlayMode = .expanded; isOverlayVisible = true; visibilityReason = reason
    }
    func deactivateOverlay() {
        interactionState = .idle; overlayMode = .compact; overlayIntent = .userRequestedClose
    }
    
    func pinOverlay() {
        interactionState = .pinned
    }
    
    func unpinOverlay() {
        interactionState = .active
    }
    
    func armOverlay() {
        if interactionState == .idle {
            interactionState = .armed
        }
    }
    
    func disarmOverlay() {
        if interactionState == .armed {
            interactionState = .idle
        }
    }
    
    func forceCloseOverlay() {
        deactivateOverlay()
    }
    
    func updateDockEdge(windowFrame: NSRect, screenFrame: NSRect) {
        // ... (existing stub)
    }
    
    func updateFile(url: URL) {
        logEvent("File updated: \(url.lastPathComponent)")
        payload = .file(url)
        fileVault.addFile(url: url)
    }
    
    func updateClipboard(text: String) {
        lastCopiedAt = Date()
        logEvent("Clipboard updated: \(text.prefix(20))...")
        payload = .clipboard(text)
        clipVault.addItem(content: text, type: .text, sourceBundleID: nil, sourceAppName: nil, imageData: nil)
    }
    
    func markCopied() {
        lastCopiedAt = Date()
        hint = L("hint_copied")
        // Automatic hint dismissal
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            if self?.hint == self?.L("hint_copied") {
                self?.hint = nil
            }
        }
    }
    
    func addToTray(url: URL) {
        logEvent("Added to tray: \(url.lastPathComponent)")
        let newItem = TrayItem(filePath: url.path, displayName: url.lastPathComponent)
        trayItems.insert(newItem, at: 0)
        TrayStore.saveTrayItems(trayItems)
    }
    
    func removeFromTray(id: UUID) {
        trayItems.removeAll { $0.id == id }
        TrayStore.saveTrayItems(trayItems)
    }
    
    func clearTray() {
        trayItems.removeAll()
        TrayStore.saveTrayItems(trayItems)
    }
    
    func clear() {
        payload = .none
        hint = nil
    }
    
    func logEvent(_ message: String) {
        let logger = os.Logger(subsystem: "com.maclingdonggao.app", category: "state")
        logger.info("\(message)")
        
        lastEventDescription = message
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        lastEventTimestamp = formatter.string(from: Date())
    }
    
    // MARK: - Global Drag Detection (Boring Notch Style)
    
    private func setupGlobalDragDetector() {
        let detector = DragDetectorManager.shared
        
        // 当拖拽进入刘海区域时
        detector.onDragEntersNotchRegion = { [weak self] in
            Task { @MainActor in
                self?.isGlobalDragActive = true
                self?.isDraggingOver = true
                self?.logEvent("🎯 Drag entered notch region")
                
                // 如果在收起状态，展开到文件区
                if self?.overlayMode == .compact {
                    self?.activateOverlay(reason: .dragDetected)
                    self?.currentSection = .files
                }
            }
        }
        
        // 当拖拽离开刘海区域时
        detector.onDragExitsNotchRegion = { [weak self] in
            Task { @MainActor in
                self?.isGlobalDragActive = false
                self?.isDraggingOver = false
                self?.logEvent("📤 Drag exited notch region")
            }
        }

        // ⚠️ Fallback drop handler: fires when SwiftUI `.onDrop` is blocked by NSPanel settings
        detector.onDropInNotchRegion = { [weak self] urls in
            Task { @MainActor in
                self?.logEvent("💥 Fallback drop triggered with \(urls.count) files")

                // Convert URLs -> ShelfItems and add to the shelf
                for url in urls {
                    let bookmarkData = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                    let item = ShelfItem(url: url, bookmarkData: bookmarkData)
                    if !ShelfStateViewModel.shared.items.contains(where: { $0.url == item.url }) {
                        withAnimation(.spring()) {
                            ShelfStateViewModel.shared.items.insert(item, at: 0)
                        }
                    }
                }

                ShelfStateViewModel.shared.saveItems()
                self?.isDraggingOver = false
                self?.isGlobalDragActive = false
            }
        }
        
        // 启动监听
        detector.startMonitoring()
    }
    
    func updateNotchRegion(_ region: CGRect) {
        DragDetectorManager.shared.updateNotchRegion(region)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let dragEnteredIslandVicinity = Notification.Name("dragEnteredIslandVicinity")
    static let dragExitedIslandVicinity = Notification.Name("dragExitedIslandVicinity")
}
