import Combine
import Foundation
import AppKit
import os

/// Memory management and optimization utility
class MemoryManager {
    static let shared = MemoryManager()
    
    private var imageCache = NSCache<NSString, NSImage>()
    private var dataCache = NSCache<NSString, NSData>()
    
    private init() {
        setupCaches()
        observeMemoryWarnings()
    }
    
    // MARK: - Setup
    
    private func setupCaches() {
        // Image cache: 50 MB
        imageCache.totalCostLimit = 50 * 1024 * 1024
        imageCache.countLimit = 100
        
        // Data cache: 30 MB
        dataCache.totalCostLimit = 30 * 1024 * 1024
        dataCache.countLimit = 50
    }
    
    private func observeMemoryWarnings() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        clearCaches()
        logInfo("Memory warning received, caches cleared")
    }
    
    // MARK: - Image Cache
    
    func cacheImage(_ image: NSImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * 4) // RGBA
        imageCache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    func cachedImage(forKey key: String) -> NSImage? {
        return imageCache.object(forKey: key as NSString)
    }
    
    func removeImage(forKey key: String) {
        imageCache.removeObject(forKey: key as NSString)
    }
    
    // MARK: - Data Cache
    
    func cacheData(_ data: Data, forKey key: String) {
        dataCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
    }
    
    func cachedData(forKey key: String) -> Data? {
        return dataCache.object(forKey: key as NSString) as Data?
    }
    
    func removeData(forKey key: String) {
        dataCache.removeObject(forKey: key as NSString)
    }
    
    // MARK: - Cache Management
    
    func clearCaches() {
        imageCache.removeAllObjects()
        dataCache.removeAllObjects()
    }
    
    func clearImageCache() {
        imageCache.removeAllObjects()
    }
    
    func clearDataCache() {
        dataCache.removeAllObjects()
    }
    
    // MARK: - Memory Info
    
    func currentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
    
    func formattedMemoryUsage() -> String {
        let bytes = currentMemoryUsage()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    func logMemoryUsage() {
        logInfo("Current memory usage: \(formattedMemoryUsage())")
    }
    
    // MARK: - Optimization
    
    func compactMemory() {
        clearCaches()
        
        // Force garbage collection hint
        autoreleasepool {
            // Trigger autorelease pool drain
        }
        
        logInfo("Memory compacted")
    }
    
    private func logInfo(_ message: String) {
        let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "MemoryManager")
        logger.info("\(message, privacy: .public)")
    }
}

// MARK: - Global Functions

func cacheImage(_ image: NSImage, forKey key: String) {
    MemoryManager.shared.cacheImage(image, forKey: key)
}

func getCachedImage(forKey key: String) -> NSImage? {
    return MemoryManager.shared.cachedImage(forKey: key)
}
