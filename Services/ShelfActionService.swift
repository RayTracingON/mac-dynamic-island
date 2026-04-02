import Foundation
import AppKit

/// Service for performing actions on shelf items
class ShelfActionService {
    static let shared = ShelfActionService()
    
    private let quickLookService = QuickLookService.shared
    private let shareService = ShareService.shared
    
    private init() {}
    
    // MARK: - Open Actions
    
    // MARK: - Open Actions
    
    func open(item: ShelfItem) {
        guard item.startAccessing() else {
            print("Failed to access file")
            return
        }
        
        defer {
            item.stopAccessing()
        }
        
        NSWorkspace.shared.open(item.url)
    }
    
    func openWith(item: ShelfItem, application: String) {
        guard item.startAccessing() else {
            print("Failed to access file")
            return
        }
        
        defer {
            item.stopAccessing()
        }
        
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([item.url], withApplicationAt: URL(fileURLWithPath: application), configuration: configuration)
    }
    
    func openInDefaultApp(item: ShelfItem) {
        open(item: item)
    }
    
    // MARK: - Reveal Actions
    
    func revealInFinder(item: ShelfItem) {
        guard item.startAccessing() else {
            print("Failed to access file")
            return
        }
        
        defer {
            item.stopAccessing()
        }
        
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }
    
    // MARK: - QuickLook
    
    func quickLook(item: ShelfItem) {
        guard item.startAccessing() else {
            print("Failed to access file")
            return
        }
        
        quickLookService.preview(url: item.url)
        // Don't stop accessing - QuickLook needs it
    }
    
    func quickLook(items: [ShelfItem]) {
        let urls = items.compactMap { item -> URL? in
            guard item.startAccessing() else { return nil }
            return item.url
        }
        
        quickLookService.preview(urls: urls)
    }
    
    // MARK: - Share Actions
    
    func share(item: ShelfItem) {
        guard item.startAccessing() else {
            print("Failed to access file")
            return
        }
        
        defer {
            item.stopAccessing()
        }
        
        shareService.share(urls: [item.url])
    }
    
    func share(items: [ShelfItem]) {
        let urls = items.compactMap { item -> URL? in
            guard item.startAccessing() else { return nil }
            defer { item.stopAccessing() }
            return item.url
        }
        
        shareService.share(urls: urls)
    }
    
    func shareViaEmail(item: ShelfItem) {
        guard item.startAccessing() else { return }
        defer { item.stopAccessing() }
        
        shareService.sendEmail(urls: [item.url])
    }
    
    func shareViaAirDrop(item: ShelfItem) {
        guard item.startAccessing() else { return }
        defer { item.stopAccessing() }
        
        shareService.shareViaAirDrop(urls: [item.url])
    }
    
    // MARK: - Copy Actions
    
    func copyToClipboard(item: ShelfItem) {
        guard item.startAccessing() else { return }
        defer { item.stopAccessing() }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([item.url as NSURL])
    }
    
    func copyPath(item: ShelfItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.url.path, forType: .string)
    }
    
    // MARK: - File Operations
    
    func duplicate(item: ShelfItem) throws -> URL {
        guard item.startAccessing() else {
            throw ActionError.accessDenied
        }
        
        defer {
            item.stopAccessing()
        }
        
        let directory = item.url.deletingLastPathComponent()
        let name = item.url.deletingPathExtension().lastPathComponent
        let ext = item.url.pathExtension
        let newName = "\(name) copy"
        let newURL = directory.appendingPathComponent(newName).appendingPathExtension(ext)
        
        try FileManager.default.copyItem(at: item.url, to: newURL)
        return newURL
    }
    
    /// Renames an item and returns the updated ShelfItem.
    /// Since ShelfItem is a struct, we cannot mutate it in place.
    func rename(item: ShelfItem, newName: String) throws -> ShelfItem {
        guard item.startAccessing() else {
            throw ActionError.accessDenied
        }
        
        defer {
            item.stopAccessing()
        }
        
        let directory = item.url.deletingLastPathComponent()
        let ext = item.url.pathExtension
        let newURL = directory.appendingPathComponent(newName).appendingPathExtension(ext)
        
        try FileManager.default.moveItem(at: item.url, to: newURL)
        
        // Return a new ShelfItem with updated properties
        var newItem = item
        newItem.url = newURL
        newItem.name = newName
        return newItem
    }
    
    func moveToTrash(item: ShelfItem) throws {
        guard item.startAccessing() else {
            throw ActionError.accessDenied
        }
        
        defer {
            item.stopAccessing()
        }
        
        try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
    }
    
    // MARK: - Get Info
    
    func getInfo(item: ShelfItem) -> String {
        guard item.startAccessing() else { return "Access Denied" }
        defer { item.stopAccessing() }
        
        let attr = try? FileManager.default.attributesOfItem(atPath: item.url.path)
        let size = (attr?[.size] as? Int64) ?? 0
        let created = (attr?[.creationDate] as? Date)?.formatted() ?? "Unknown"
        
        return """
        Name: \(item.displayName)
        Size: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
        Created: \(created)
        Path: \(item.url.path)
        """
    }
    
    func showInfoInFinder(item: ShelfItem) {
        guard item.startAccessing() else { return }
        defer { item.stopAccessing() }
        
        // Show file info panel
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
        
        // Send Command+I to show info
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let source = CGEventSource(stateID: .hidSystemState)
            
            // Command key down
            let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
            cmdDown?.flags = .maskCommand
            
            // I key down
            let iDown = CGEvent(keyboardEventSource: source, virtualKey: 0x22, keyDown: true)
            iDown?.flags = .maskCommand
            
            // I key up
            let iUp = CGEvent(keyboardEventSource: source, virtualKey: 0x22, keyDown: false)
            iUp?.flags = .maskCommand
            
            // Command key up
            let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
            
            cmdDown?.post(tap: .cghidEventTap)
            iDown?.post(tap: .cghidEventTap)
            iUp?.post(tap: .cghidEventTap)
            cmdUp?.post(tap: .cghidEventTap)
        }
    }
}

enum ActionError: Error {
    case accessDenied
    case operationFailed
}
