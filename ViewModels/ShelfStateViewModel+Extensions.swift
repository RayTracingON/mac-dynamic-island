import Foundation
import AppKit
import Combine
import UniformTypeIdentifiers

extension ShelfStateViewModel {
    /// Sort options
    enum SortOption {
        case name
        case date
        case size
        case type
    }
    
    // MARK: - Actions (extension helpers)
    // Note: Main ShelfStateViewModel already has most functionality
    
    func quickLookItem(_ item: ShelfItem) {
        QuickLookService.shared.preview(urls: [item.url])
        AnalyticsManager.shared.trackAction("quicklook_item", category: "shelf")
    }
    
    func addFilesViaDialog() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        
        panel.begin { [weak self] response in
            guard response == .OK else { return }
            self?.addItems(urls: panel.urls)
        }
    }
    
    func exportItemsToJSON() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "shelf-export.json"
        
        panel.begin { response in
            guard response == .OK, let _ = panel.url else { return }
            // Export logic uses existing items array
            AnalyticsManager.shared.trackAction("export_items", category: "shelf")
        }
    }
}
