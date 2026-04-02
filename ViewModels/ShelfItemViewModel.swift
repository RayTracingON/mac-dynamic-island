import Foundation
import SwiftUI
import Combine
import AppKit

/// View model for individual shelf item
@MainActor
final class ShelfItemViewModel: ObservableObject, Identifiable {
    let id: UUID
    @Published var item: ShelfItem
    @Published var thumbnail: NSImage?
    @Published var isLoading: Bool = false
    
    private let thumbnailService = ThumbnailService.shared
    
    init(item: ShelfItem) {
        self.id = item.id
        self.item = item
        loadThumbnail()
    }
    
    func loadThumbnail() {
        Task { @MainActor in
            guard let resolvedURL = ShelfStateViewModel.shared.resolveFileURL(for: item) else { return }
            self.thumbnail = NSWorkspace.shared.icon(forFile: resolvedURL.path)
        }
    }
    
    @Published var isSelected: Bool = false
    @Published var isHovered: Bool = false
    
    var fileName: String {
        item.displayName
    }
    
    // MARK: - Actions
    
    func open() {
        if let url = ShelfStateViewModel.shared.resolveFileURL(for: item) {
            NSWorkspace.shared.open(url)
        }
    }
    
    func revealInFinder() {
        if let url = ShelfStateViewModel.shared.resolveFileURL(for: item) {
            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
        }
    }
    
    func quickLook() {
        if let url = ShelfStateViewModel.shared.resolveFileURL(for: item) {
             QuickLookService.shared.preview(url: url)
        }
    }
    
    func share() {
        if let url = ShelfStateViewModel.shared.resolveFileURL(for: item) {
             ShareService.shared.share(urls: [url])
        }
    }
    
    func copyURL() {
        if let url = ShelfStateViewModel.shared.resolveFileURL(for: item) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([url as NSURL])
        }
    }
    
    func copyPath() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.url.path, forType: .string)
    }
}
