import Combine
import AppKit
import CoreImage

/// Image processing utilities
class ImageProcessor {
    static let shared = ImageProcessor()
    
    private let context = CIContext()
    
    private init() {}
    
    // MARK: - Resizing
    
    func resize(_ image: NSImage, to size: CGSize) -> NSImage? {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        
        newImage.unlockFocus()
        return newImage
    }
    
    func scaleToFit(_ image: NSImage, in size: CGSize) -> NSImage? {
        let aspectRatio = image.size.width / image.size.height
        let targetAspectRatio = size.width / size.height
        
        var newSize = size
        if aspectRatio > targetAspectRatio {
            newSize.height = size.width / aspectRatio
        } else {
            newSize.width = size.height * aspectRatio
        }
        
        return resize(image, to: newSize)
    }
    
    func scaleToFill(_ image: NSImage, in size: CGSize) -> NSImage? {
        let aspectRatio = image.size.width / image.size.height
        let targetAspectRatio = size.width / size.height
        
        var newSize = size
        if aspectRatio > targetAspectRatio {
            newSize.width = size.height * aspectRatio
        } else {
            newSize.height = size.width / aspectRatio
        }
        
        return resize(image, to: newSize)
    }
    
    // MARK: - Cropping
    
    func crop(_ image: NSImage, to rect: CGRect) -> NSImage? {
        guard let imageData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: imageData),
              let cgImage = bitmap.cgImage else {
            return nil
        }
        
        guard let croppedCGImage = cgImage.cropping(to: rect) else {
            return nil
        }
        
        let croppedImage = NSImage(cgImage: croppedCGImage, size: rect.size)
        return croppedImage
    }
    
    func cropToSquare(_ image: NSImage) -> NSImage? {
        let size = min(image.size.width, image.size.height)
        let x = (image.size.width - size) / 2
        let y = (image.size.height - size) / 2
        
        return crop(image, to: CGRect(x: x, y: y, width: size, height: size))
    }
    
    // MARK: - Filters
    
    func applyBlur(_ image: NSImage, radius: Double = 10) -> NSImage? {
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else {
            return nil
        }
        
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        
        guard let outputImage = filter?.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: image.size)
    }
    
    func adjustBrightness(_ image: NSImage, by value: Double) -> NSImage? {
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else {
            return nil
        }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(value, forKey: kCIInputBrightnessKey)
        
        guard let outputImage = filter?.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: image.size)
    }
    
    func adjustContrast(_ image: NSImage, by value: Double) -> NSImage? {
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else {
            return nil
        }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(value, forKey: kCIInputContrastKey)
        
        guard let outputImage = filter?.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: image.size)
    }
    
    func adjustSaturation(_ image: NSImage, by value: Double) -> NSImage? {
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else {
            return nil
        }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(value, forKey: kCIInputSaturationKey)
        
        guard let outputImage = filter?.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: image.size)
    }
    
    // MARK: - Effects
    
    func makeRounded(_ image: NSImage, cornerRadius: CGFloat) -> NSImage? {
        let size = image.size
        let newImage = NSImage(size: size)
        
        newImage.lockFocus()
        
        let rect = NSRect(origin: .zero, size: size)
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        path.addClip()
        
        image.draw(at: .zero, from: rect, operation: .sourceOver, fraction: 1.0)
        
        newImage.unlockFocus()
        return newImage
    }
    
    func makeCircular(_ image: NSImage) -> NSImage? {
        guard let square = cropToSquare(image) else {
            return nil
        }
        
        let size = square.size
        let newImage = NSImage(size: size)
        
        newImage.lockFocus()
        
        let rect = NSRect(origin: .zero, size: size)
        let path = NSBezierPath(ovalIn: rect)
        path.addClip()
        
        square.draw(at: .zero, from: rect, operation: .sourceOver, fraction: 1.0)
        
        newImage.unlockFocus()
        return newImage
    }
    
    func addShadow(_ image: NSImage, offset: CGSize = CGSize(width: 0, height: -3), blur: CGFloat = 5) -> NSImage? {
        let shadowPadding: CGFloat = blur * 2
        let newSize = CGSize(
            width: image.size.width + shadowPadding * 2,
            height: image.size.height + shadowPadding * 2
        )
        
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        
        let shadow = NSShadow()
        shadow.shadowOffset = offset
        shadow.shadowBlurRadius = blur
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.set()
        
        let drawRect = NSRect(
            x: shadowPadding,
            y: shadowPadding,
            width: image.size.width,
            height: image.size.height
        )
        image.draw(in: drawRect)
        
        newImage.unlockFocus()
        return newImage
    }
    
    // MARK: - Conversion
    
    func tintedImage(_ image: NSImage, color: NSColor) -> NSImage? {
        let newImage = NSImage(size: image.size)
        newImage.lockFocus()
        
        let rect = NSRect(origin: .zero, size: image.size)
        image.draw(in: rect)
        
        color.set()
        rect.fill(using: .sourceAtop)
        
        newImage.unlockFocus()
        return newImage
    }
    
    func grayscale(_ image: NSImage) -> NSImage? {
        guard let ciImage = CIImage(data: image.tiffRepresentation!) else {
            return nil
        }
        
        let filter = CIFilter(name: "CIPhotoEffectMono")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter?.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: image.size)
    }
}
