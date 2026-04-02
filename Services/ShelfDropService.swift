import Foundation
import AppKit
import UniformTypeIdentifiers

/// Service for handling drag and drop operations on the shelf
class ShelfDropService {
    static let shared = ShelfDropService()
    
    private init() {}
    
    // MARK: - Drop Validation
    
    func canAcceptDrop(providers: [NSItemProvider]) -> Bool {
        return providers.contains { provider in
            provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) ||
            provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) ||
            provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) ||
            provider.hasItemConformingToTypeIdentifier(UTType.image.identifier)
        }
    }
    
    func getDropTypes() -> [UTType] {
        return [.fileURL, .url, .text, .image]
    }
    
    // MARK: - URL Extraction
    
    func extractURLs(from providers: [NSItemProvider]) async -> [URL] {
        var urls: [URL] = []
        
        for provider in providers {
            // Try file URL first
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                if let url = await extractFileURL(from: provider) {
                    urls.append(url)
                }
            }
            // Try regular URL
            else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                if let url = await extractURL(from: provider) {
                    urls.append(url)
                }
            }
            // Try text (might contain URL)
            else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                if let url = await extractURLFromText(from: provider) {
                    urls.append(url)
                }
            }
            // Try image
            else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                if let url = await extractImageAsFile(from: provider) {
                    urls.append(url)
                }
            }
        }
        
        return urls
    }
    
    private func extractFileURL(from provider: NSItemProvider) async -> URL? {
        do {
            let data = try await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier)
            
            if let urlData = data as? Data {
                return URL(dataRepresentation: urlData, relativeTo: nil)
            } else if let url = data as? URL {
                return url
            } else if let string = data as? String {
                return URL(string: string)
            }
        } catch {
            print("Failed to extract file URL: \(error)")
        }
        
        return nil
    }
    
    private func extractURL(from provider: NSItemProvider) async -> URL? {
        do {
            let data = try await provider.loadItem(forTypeIdentifier: UTType.url.identifier)
            
            if let url = data as? URL {
                return url
            } else if let string = data as? String {
                return URL(string: string)
            } else if let urlData = data as? Data {
                return URL(dataRepresentation: urlData, relativeTo: nil)
            }
        } catch {
            print("Failed to extract URL: \(error)")
        }
        
        return nil
    }
    
    private func extractURLFromText(from provider: NSItemProvider) async -> URL? {
        do {
            let data = try await provider.loadItem(forTypeIdentifier: UTType.text.identifier)
            
            if let string = data as? String {
                // Try to parse as URL
                if let url = URL(string: string), url.scheme != nil {
                    return url
                }
                
                // Save as text file
                return try saveTextAsFile(string)
            }
        } catch {
            print("Failed to extract text: \(error)")
        }
        
        return nil
    }
    
    private func extractImageAsFile(from provider: NSItemProvider) async -> URL? {
        do {
            let data = try await provider.loadItem(forTypeIdentifier: UTType.image.identifier)
            
            if let image = data as? NSImage {
                return try saveImageAsFile(image)
            } else if let imageData = data as? Data {
                return try saveDataAsFile(imageData, ext: "png")
            }
        } catch {
            print("Failed to extract image: \(error)")
        }
        
        return nil
    }
    
    // MARK: - File Saving
    
    private func saveTextAsFile(_ text: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "Dropped Text \(Date().formatted(date: .numeric, time: .shortened)).txt"
        let fileURL = tempDir.appendingPathComponent(filename)
        
        try text.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private func saveImageAsFile(_ image: NSImage) throws -> URL {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw DropError.imageConversionFailed
        }
        
        return try saveDataAsFile(pngData, ext: "png")
    }
    
    private func saveDataAsFile(_ data: Data, ext: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "Dropped File \(Date().formatted(date: .numeric, time: .shortened)).\(ext)"
        let fileURL = tempDir.appendingPathComponent(filename)
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    // MARK: - Drop Handling
    
    func handleDrop(info: DropInfo, shelfState: ShelfStateViewModel) async {
        let providers = info.itemProviders(for: getDropTypes())
        let urls = await extractURLs(from: providers)
        
        await MainActor.run {
            shelfState.addItems(urls: urls)
        }
    }
    
    // MARK: - Drag Validation
    
    func validateDrop(info: DropInfo) -> Bool {
        return canAcceptDrop(providers: info.itemProviders(for: getDropTypes()))
    }
}

// MARK: - Drop Info Protocol

protocol DropInfo {
    func itemProviders(for types: [UTType]) -> [NSItemProvider]
}

// MARK: - Errors

enum DropError: Error {
    case imageConversionFailed
    case unsupportedType
    case saveFailed
}
