//
//  Color+Extensions.swift
//  Mac灵动岛
//
//  Stage 1: Color utilities from boringNotch
//

import SwiftUI
import AppKit

extension Color {
    /// Ensure minimum brightness for readability
    func ensureMinimumBrightness(factor: Double = 0.6) -> Color {
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else { return self }
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        rgbColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        if brightness < CGFloat(factor) {
            brightness = CGFloat(factor)
        }
        
        return Color(nsColor: NSColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha))
    }
    
    /// Get effective accent color (system or custom)
    static var effectiveAccent: Color {
        return Color.accentColor
    }
    
    /// Create color from hex string (optional failable initializer)
    init?(hexCode: String) {
        let hex = hexCode.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension NSColor {
    /// Average brightness of color
    var brightness: CGFloat {
        guard let rgbColor = self.usingColorSpace(.deviceRGB) else { return 0 }
        var brightness: CGFloat = 0
        rgbColor.getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)
        return brightness
    }
}
