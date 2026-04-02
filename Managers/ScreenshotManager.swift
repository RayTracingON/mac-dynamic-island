import Foundation
import AppKit

#if APP_STORE
/// Stub implementation for App Store builds (screenshot via Process not available in sandbox)
class ScreenshotManager {
    static let shared = ScreenshotManager()
    
    private init() {}
    
    func captureScreen(displayID: CGDirectDisplayID? = nil) -> NSImage? { nil }
    func captureWindow(windowID: CGWindowID) -> NSImage? { nil }
    func captureRect(_ rect: CGRect) -> NSImage? { nil }
    func captureWithSelection(completion: @escaping (NSImage?) -> Void) { completion(nil) }
    func saveScreenshot(_ image: NSImage, to url: URL) throws { throw ScreenshotError.captureFailed }
    func saveToDesktop(_ image: NSImage, filename: String = "Screenshot") -> URL? { nil }
    func copyToClipboard(_ image: NSImage) {}
    func getAllWindows() -> [[String: Any]] { [] }
}
#else
import ScreenCaptureKit

/// Manager for taking screenshots
/// Note: Using Process to run screencapture is not allowed in sandboxed App Store apps
class ScreenshotManager {
    static let shared = ScreenshotManager()
    
    private init() {}
    
    // MARK: - Capture Methods
    
    /// Capture entire screen using screencapture utility (ScreenCaptureKit compatible)
    func captureScreen(displayID: CGDirectDisplayID? = nil) -> NSImage? {
        // Use screencapture utility which is always available
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("screen-\(UUID().uuidString).png")
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        task.arguments = ["-x", "-C", tempURL.path]  // -x = no sound, -C = capture cursor
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if FileManager.default.fileExists(atPath: tempURL.path),
               let image = NSImage(contentsOf: tempURL) {
                try? FileManager.default.removeItem(at: tempURL)
                return image
            }
        } catch {
            print("Screenshot capture failed: \(error)")
        }
        
        return nil
    }
    
    /// Capture specific window using screencapture
    func captureWindow(windowID: CGWindowID) -> NSImage? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("window-\(UUID().uuidString).png")
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        task.arguments = ["-x", "-l", "\(windowID)", tempURL.path]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if FileManager.default.fileExists(atPath: tempURL.path),
               let image = NSImage(contentsOf: tempURL) {
                try? FileManager.default.removeItem(at: tempURL)
                return image
            }
        } catch {
            print("Window capture failed: \(error)")
        }
        
        return nil
    }
    
    /// Capture specific rect on screen using screencapture
    func captureRect(_ rect: CGRect) -> NSImage? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("rect-\(UUID().uuidString).png")
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        // Use -R for rectangle: x,y,width,height
        let rectString = "\(Int(rect.origin.x)),\(Int(rect.origin.y)),\(Int(rect.width)),\(Int(rect.height))"
        task.arguments = ["-x", "-R", rectString, tempURL.path]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if FileManager.default.fileExists(atPath: tempURL.path),
               let image = NSImage(contentsOf: tempURL) {
                try? FileManager.default.removeItem(at: tempURL)
                return image
            }
        } catch {
            print("Rect capture failed: \(error)")
        }
        
        return nil
    }
    
    /// Capture with selection
    func captureWithSelection(completion: @escaping (NSImage?) -> Void) {
        // Launch screencapture utility with interactive mode
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("screenshot-\(UUID().uuidString).png")
        
        task.arguments = ["-i", "-s", tempURL.path]
        
        task.terminationHandler = { _ in
            DispatchQueue.main.async {
                if FileManager.default.fileExists(atPath: tempURL.path),
                   let image = NSImage(contentsOf: tempURL) {
                    completion(image)
                    try? FileManager.default.removeItem(at: tempURL)
                } else {
                    completion(nil)
                }
            }
        }
        
        try? task.run()
    }
    
    // MARK: - Save
    
    func saveScreenshot(_ image: NSImage, to url: URL) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            throw ScreenshotError.saveFailed
        }
        
        try pngData.write(to: url)
    }
    
    func saveToDesktop(_ image: NSImage, filename: String = "Screenshot") -> URL? {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: ".")
        
        let url = desktop.appendingPathComponent("\(filename) \(timestamp).png")
        
        do {
            try saveScreenshot(image, to: url)
            return url
        } catch {
            print("Failed to save screenshot: \(error)")
            return nil
        }
    }
    
    // MARK: - Utilities
    
    func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
    
    func getAllWindows() -> [[String: Any]] {
        guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        return windows
    }
}

#endif

enum ScreenshotError: Error {
    case captureFailed
    case saveFailed
    case windowNotFound
}
