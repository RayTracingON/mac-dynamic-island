import Foundation
import AppKit
import CoreImage
import Vision

/// Service for advanced image processing operations
class ImageProcessingService {
    static let shared = ImageProcessingService()
    
    private let ciContext = CIContext()
    
    private init() {}
    
    // MARK: - Image Analysis
    
    /// Detect dominant colors in an image
    func extractDominantColors(from image: NSImage, count: Int = 3) -> [NSColor] {
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else {
            return []
        }
        
        let extents = ciImage.extent
        let width = Int(extents.width)
        let height = Int(extents.height)
        
        // Sample colors from image
        var colorCounts: [NSColor: Int] = [:]
        let sampleRate = 10 // Sample every 10th pixel
        
        for x in stride(from: 0, to: width, by: sampleRate) {
            for y in stride(from: 0, to: height, by: sampleRate) {
                if let color = getPixelColor(from: ciImage, at: CGPoint(x: x, y: y)) {
                    let quantized = quantizeColor(color)
                    colorCounts[quantized, default: 0] += 1
                }
            }
        }
        
        // Sort by frequency
        let sortedColors = colorCounts.sorted { $0.value > $1.value }
        return Array(sortedColors.prefix(count).map { $0.key })
    }
    
    private func getPixelColor(from image: CIImage, at point: CGPoint) -> NSColor? {
        let bitmap = NSBitmapImageRep(ciImage: image)
        guard let color = bitmap.colorAt(x: Int(point.x), y: Int(point.y)) else {
            return nil
        }
        return color
    }
    
    private func quantizeColor(_ color: NSColor) -> NSColor {
        let step: CGFloat = 0.2
        let r = round(color.redComponent / step) * step
        let g = round(color.greenComponent / step) * step
        let b = round(color.blueComponent / step) * step
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    // MARK: - Image Effects
    
    /// Apply blur effect to image
    func applyBlur(to image: NSImage, radius: Double = 10) -> NSImage? {
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else {
            return nil
        }
        
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter?.outputImage,
              let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: image.size)
    }
    
    /// Apply tint to image
    func applyTint(to image: NSImage, color: NSColor) -> NSImage? {
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else {
            return nil
        }
        
        let filter = CIFilter(name: "CIColorMonochrome")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(CIColor(color: color), forKey: kCIInputColorKey)
        filter?.setValue(1.0, forKey: kCIInputIntensityKey)
        
        guard let outputImage = filter?.outputImage,
              let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: image.size)
    }
    
    /// Adjust brightness and contrast
    func adjustLevels(image: NSImage, brightness: Double = 0, contrast: Double = 1) -> NSImage? {
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else {
            return nil
        }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter?.setValue(contrast, forKey: kCIInputContrastKey)
        
        guard let outputImage = filter?.outputImage,
              let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: image.size)
    }
    
    // MARK: - Image Transformation
    
    /// Resize image to target size
    func resize(image: NSImage, to size: CGSize) -> NSImage {
        let resized = NSImage(size: size)
        resized.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: size),
                  from: NSRect(origin: .zero, size: image.size),
                  operation: .copy,
                  fraction: 1.0)
        
        resized.unlockFocus()
        return resized
    }
    
    /// Crop image to rect
    func crop(image: NSImage, to rect: CGRect) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        guard let cropped = cgImage.cropping(to: rect) else {
            return nil
        }
        
        return NSImage(cgImage: cropped, size: rect.size)
    }
    
    /// Rotate image by degrees
    func rotate(image: NSImage, degrees: CGFloat) -> NSImage {
        let rotated = NSImage(size: image.size)
        rotated.lockFocus()
        
        let transform = NSAffineTransform()
        transform.translateX(by: image.size.width / 2, yBy: image.size.height / 2)
        transform.rotate(byDegrees: degrees)
        transform.translateX(by: -image.size.width / 2, yBy: -image.size.height / 2)
        transform.concat()
        
        image.draw(at: .zero, from: .zero, operation: .copy, fraction: 1.0)
        
        rotated.unlockFocus()
        return rotated
    }
    
    // MARK: - Utilities
    
    /// Convert image to JPEG data
    func convertToJPEG(image: NSImage, compressionQuality: CGFloat = 0.8) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
    
    /// Convert image to PNG data
    func convertToPNG(image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmap.representation(using: .png, properties: [:])
    }
}
