import Foundation
import AppKit

/// Service for quick sharing actions without picker
class QuickShareService {
    static let shared = QuickShareService()
    
    private init() {}
    
    // MARK: - Quick Actions
    
    /// Copy file URL to clipboard
    func copyURL(_ url: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([url as NSURL])
    }
    
    /// Copy file path to clipboard
    func copyPath(_ url: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.path, forType: .string)
    }
    
    /// Copy file name to clipboard
    func copyName(_ url: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.lastPathComponent, forType: .string)
    }
    
    /// Share via email
    func shareViaEmail(urls: [URL]) {
        guard let service = NSSharingService(named: .composeEmail) else { return }
        
        if service.canPerform(withItems: urls) {
            service.perform(withItems: urls)
        }
    }
    
    /// Share via Messages
    func shareViaMessages(urls: [URL]) {
        guard let service = NSSharingService(named: .composeMessage) else { return }
        
        if service.canPerform(withItems: urls) {
            service.perform(withItems: urls)
        }
    }
    
    /// Share via AirDrop
    func shareViaAirDrop(urls: [URL]) {
        guard let service = NSSharingService(named: .sendViaAirDrop) else { return }
        
        if service.canPerform(withItems: urls) {
            service.perform(withItems: urls)
        }
    }
    
    /// Add to Photos
    func addToPhotos(urls: [URL]) {
        guard let service = NSSharingService(named: .addToIPhoto) else { return }
        
        if service.canPerform(withItems: urls) {
            service.perform(withItems: urls)
        }
    }
    
    /// Post to social media
    /// Post to social media
    func postToTwitter(urls: [URL], text: String? = nil) {
        // NSSharingService .postOnTwitter was deprecated and removed.
        // This functionality is no longer supported directly via system sharing services.
        print("Twitter sharing service is no longer available.")
    }
    
    // MARK: - Batch Operations
    
    /// Copy multiple URLs
    func copyMultiple(urls: [URL]) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(urls as [NSURL])
    }
    
    /// Create zip archive and share
    func createArchiveAndShare(urls: [URL], completion: @escaping (Result<URL, Error>) -> Void) {
        guard !urls.isEmpty else {
            completion(.failure(QuickShareError.noItems))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let tempDir = FileManager.default.temporaryDirectory
                let archiveName = "Archive-\(Date().timeIntervalSince1970).zip"
                let archiveURL = tempDir.appendingPathComponent(archiveName)
                
                // Create archive using ditto (macOS built-in)
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
                process.arguments = ["-c", "-k", "--sequesterRsrc", "--keepParent"] + urls.map { $0.path } + [archiveURL.path]
                
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    DispatchQueue.main.async {
                        completion(.success(archiveURL))
                    }
                } else {
                    throw QuickShareError.archiveFailed
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Utilities
    
    /// Check if service is available
    func isServiceAvailable(_ serviceName: NSSharingService.Name) -> Bool {
        return NSSharingService(named: serviceName) != nil
    }
    
    /// Get all available services for items
    @available(*, deprecated, message: "Use NSSharingServicePicker directly instead")
    func availableServices(for items: [Any]) -> [NSSharingService] {
        return NSSharingService.sharingServices(forItems: items)
    }
}

enum QuickShareError: Error {
    case noItems
    case archiveFailed
    case serviceUnavailable
}
