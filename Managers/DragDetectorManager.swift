import Cocoa
import UniformTypeIdentifiers

/// 全局拖拽检测器 - 借鉴 Boring Notch 实现
/// 用于检测系统级别的文件拖拽，当拖拽进入刘海区域时触发回调
final class DragDetectorManager {
    
    static let shared = DragDetectorManager()
    
    // MARK: - Callbacks
    
    typealias VoidCallback = () -> Void
    typealias PositionCallback = (_ globalPoint: CGPoint) -> Void
    typealias DropCallback = (_ urls: [URL]) -> Void
    
    var onDragEntersNotchRegion: VoidCallback?
    var onDragExitsNotchRegion: VoidCallback?
    var onDragMove: PositionCallback?

    /// ⚠️ Fallback drop callback: used when SwiftUI `.onDrop` does not fire in floating panels.
    /// Triggered on global mouse up while dragging content and mouse is inside notchRegion.
    var onDropInNotchRegion: DropCallback?
    
    // MARK: - Private Properties
    
    private var mouseDownMonitor: Any?
    private var mouseDraggedMonitor: Any?
    private var mouseUpMonitor: Any?
    
    private var pasteboardChangeCount: Int = -1
    private var isDragging: Bool = false
    private var isContentDragging: Bool = false
    private var hasEnteredNotchRegion: Bool = false
    private var didFireDropForCurrentDrag: Bool = false
    
    private var notchRegion: CGRect = .zero
    private let dragPasteboard = NSPasteboard(name: .drag)
    
    // 节流相关
    private var lastProcessedTime: TimeInterval = 0
    private let throttleInterval: TimeInterval = 0.05 // 50ms 节流，从每次处理降低到 20fps
    
    private init() {}
    
    // MARK: - Public Methods
    
    func updateNotchRegion(_ region: CGRect) {
        self.notchRegion = region
    }
    
    func startMonitoring() {
        stopMonitoring()
        
        // 监听鼠标按下 - 记录剪贴板状态
        mouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] _ in
            guard let self = self else { return }
            self.pasteboardChangeCount = self.dragPasteboard.changeCount
            self.isDragging = true
            self.isContentDragging = false
            self.hasEnteredNotchRegion = false
            self.didFireDropForCurrentDrag = false
        }
        
        // 监听拖拽移动 - 检测是否进入刘海区域 (已优化:节流)
        mouseDraggedMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] _ in
            guard let self = self else { return }
            guard self.isDragging else { return }
            
            // ✅ 节流: 避免每次 mouseDragged 都处理
            let now = Date().timeIntervalSinceReferenceDate
            guard now - self.lastProcessedTime >= self.throttleInterval else { return }
            self.lastProcessedTime = now
            
            let newContent = self.dragPasteboard.changeCount != self.pasteboardChangeCount
            
            // 检测是否真的在拖拽内容（剪贴板变化 + 内容有效）
            if newContent && !self.isContentDragging && self.hasValidDragContent() {
                self.isContentDragging = true
            }
            
            // 只在拖拽内容时处理位置
            if self.isContentDragging {
                let mouseLocation = NSEvent.mouseLocation
                self.onDragMove?(mouseLocation)
                
                // 检测是否进入/退出刘海区域
                let containsMouse = self.notchRegion.contains(mouseLocation)
                if containsMouse && !self.hasEnteredNotchRegion {
                    self.hasEnteredNotchRegion = true
                    self.onDragEntersNotchRegion?()
                } else if !containsMouse && self.hasEnteredNotchRegion {
                    self.hasEnteredNotchRegion = false
                    self.onDragExitsNotchRegion?()
                }
            }
        }
        
        // 监听鼠标释放 - 触发 fallback drop（如果松手在刘海区域内）
        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            guard let self = self else { return }
            guard self.isDragging else { return }

            let mouseLocation = NSEvent.mouseLocation
            let releasedInsideNotch = self.notchRegion.contains(mouseLocation)

            if releasedInsideNotch && self.isContentDragging && !self.didFireDropForCurrentDrag {
                self.didFireDropForCurrentDrag = true

                let urls = self.extractFileURLsFromDragPasteboard()
                if !urls.isEmpty {
                    print("💥 [DragDetectorManager] Fallback drop detected. urls=\(urls.count)")
                    self.onDropInNotchRegion?(urls)
                } else {
                    print("⚠️ [DragDetectorManager] Fallback drop detected but no file URLs found.")
                }
            }
            
            self.isDragging = false
            self.isContentDragging = false
            
            // 延迟重置 region 状态，给后续 UI 处理时间
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.hasEnteredNotchRegion = false
            }
            
            self.pasteboardChangeCount = -1
        }
    }
    
    func stopMonitoring() {
        [mouseDownMonitor, mouseDraggedMonitor, mouseUpMonitor].forEach { monitor in
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
        mouseDownMonitor = nil
        mouseDraggedMonitor = nil
        mouseUpMonitor = nil
        isDragging = false
        isContentDragging = false
        hasEnteredNotchRegion = false
    }
    
    // MARK: - Private Helpers
    
    /// 检查拖拽的剪贴板是否包含有效内容
    private func hasValidDragContent() -> Bool {
        let validTypes: [NSPasteboard.PasteboardType] = [
            .fileURL,
            NSPasteboard.PasteboardType(UTType.url.identifier),
            .string
        ]
        return dragPasteboard.types?.contains(where: validTypes.contains) ?? false
    }

    private func extractFileURLsFromDragPasteboard() -> [URL] {
        // Prefer NSURL objects (most reliable for Finder drops)
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true
        ]

        if let objects = dragPasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [NSURL] {
            let urls = objects.compactMap { $0 as URL }
            return urls
        }

        // Fallback: sometimes file URLs come as plain strings
        if let strings = dragPasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [NSString] {
            let urls = strings
                .map { $0 as String }
                .compactMap { URL(string: $0) ?? URL(fileURLWithPath: $0) }
                .filter { $0.isFileURL }
            return urls
        }

        return []
    }
    
    deinit {
        stopMonitoring()
    }
}
