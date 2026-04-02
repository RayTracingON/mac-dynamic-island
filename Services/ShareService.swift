import AppKit
import SwiftUI

/// 简单分享服务，封装 macOS 系统分享
class ShareService {
    static let shared = ShareService()
    
    private init() {}
    
    /// 调用系统分享菜单 (通用)
    func share(urls: [URL]) {
        // 在后台调用 NSSharingServicePicker
        // 注意：由于我们是无窗口应用或特殊窗口，这里可能需要一个 anchor view
        // 简单起见，我们只能尝试在主线程打开
        
        DispatchQueue.main.async {
            let picker = NSSharingServicePicker(items: urls)
            // 查找最近的窗口或创建一个临时窗口
            if let window = NSApp.keyWindow ?? NSApp.windows.first {
                // 在鼠标位置显示
                // let mouseLoc = NSEvent.mouseLocation // Unused
                // 需要将屏幕坐标转换为窗口坐标... 或者简单地让它居中
                // 这是一个简化实现，通常需要传入具体的 View
                // 这里我们使用一个更有弹性的方式：
                picker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
            }
        }
    }
    
    /// 直接调用 AirDrop
    func shareViaAirDrop(urls: [URL]) {
        if let service = NSSharingService(named: NSSharingService.Name.sendViaAirDrop) {
            if service.canPerform(withItems: urls) {
                service.perform(withItems: urls)
            }
        }
    }

    
    /// 直接调用 Mail 分享
    func sendEmail(urls: [URL]) {
        if let service = NSSharingService(named: NSSharingService.Name.composeEmail) {
            if service.canPerform(withItems: urls) {
                service.perform(withItems: urls)
            }
        }
    }
}
