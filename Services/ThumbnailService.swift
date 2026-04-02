import AppKit
import QuickLookThumbnailing

/// 异步缩略图生成服务
class ThumbnailService {
    static let shared = ThumbnailService()
    
    private let cache = NSCache<NSString, NSImage>()
    
    private init() {
        cache.countLimit = 100
    }
    
    func generateThumbnail(for url: URL, completion: @escaping (NSImage?) -> Void) {
        let key = url.path as NSString
        
        // 1. Check cache
        if let cached = cache.object(forKey: key) {
            completion(cached)
            return
        }
        
        // 2. Generate
        let size = CGSize(width: 128, height: 128)
        let scale = const_high_res_scale // 假设我们想要高分屏支持，通常是 2.0
        
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .icon
        )
        
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { thumbnail, error in
            if let thumb = thumbnail {
                let nsImage = NSImage(cgImage: thumb.cgImage, size: size)
                self.cache.setObject(nsImage, forKey: key)
                DispatchQueue.main.async {
                    completion(nsImage)
                }
            } else {
                // Fallback to system icon
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    private var const_high_res_scale: CGFloat {
        NSScreen.main?.backingScaleFactor ?? 2.0
    }
}
