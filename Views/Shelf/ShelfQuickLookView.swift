import Combine
import SwiftUI
import Quartz

/// QuickLook preview panel for shelf items
struct ShelfQuickLookView: NSViewRepresentable {
    let urls: [URL]
    let currentIndex: Int
    
    func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView()
        view.autostarts = true
        return view
    }
    
    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        guard currentIndex < urls.count else { return }
        nsView.previewItem = urls[currentIndex] as QLPreviewItem
    }
}

/// QuickLook window controller
class ShelfQuickLookController: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    private var urls: [URL] = []
    private var currentIndex: Int = 0
    
    func show(urls: [URL], at index: Int = 0) {
        self.urls = urls
        self.currentIndex = index
        
        guard let panel = QLPreviewPanel.shared() else { return }
        
        panel.dataSource = self
        panel.delegate = self
        panel.currentPreviewItemIndex = index
        panel.makeKeyAndOrderFront(nil)
    }
    
    // MARK: - QLPreviewPanelDataSource
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return urls.count
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        return urls[index] as QLPreviewItem
    }
    
    // MARK: - QLPreviewPanelDelegate
    
    func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        return false
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, sourceFrameOnScreenFor item: QLPreviewItem!) -> NSRect {
        return .zero
    }
}
