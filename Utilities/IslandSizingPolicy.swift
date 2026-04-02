//
//  IslandSizingPolicy.swift
//  Mac灵动岛
//
//  DYNAMIC WIDTH — BREAKPOINT-DRIVEN SIZING
//  Width represents capability, not decoration
//

import Foundation
import CoreGraphics

struct IslandSizingPolicy {
    
    // MARK: - Width Modes
    
    enum WidthMode: String, Equatable {
        case xs    // Idle pill: 220-260px
        case s     // Compact: 320-380px (1-2 items)
        case m     // Standard: 480-560px (3-5 items)
        case l     // Wide: 680-760px (6-9 items)
        case xl    // Ultra wide: 880-1040px (10+ or manual)
        
        var displayName: String {
            switch self {
            case .xs: return "Idle"
            case .s: return "Compact"
            case .m: return "Standard"
            case .l: return "Wide"
            case .xl: return "Ultra Wide"
            }
        }
    }
    
    // MARK: - Size Metrics
    
    struct Metrics {
        let width: CGFloat
        let height: CGFloat
        let cornerRadius: CGFloat
        let contentPadding: CGFloat
        let mode: WidthMode
    }
    
    // MARK: - Breakpoint Dimensions
    // PRODUCTION-GRADE: All expanded sizes must support 3-zone layout
    
    // XS: Idle pill (closed or empty)
    private static let xsWidth: CGFloat = 280
    private static let xsHeight: CGFloat = 52
    
    // S: Compact preview (not used in new model)
    private static let sWidth: CGFloat = 360
    private static let sHeight: CGFloat = 120
    
    // M: Standard expanded - MINIMUM usable size for 3 zones
    private static let mWidth: CGFloat = 640
    private static let mHeight: CGFloat = 360
    
    // L: Wide expanded - comfortable size for more content
    private static let lWidth: CGFloat = 760
    private static let lHeight: CGFloat = 380
    
    // XL: Ultra wide - full panel for many items
    private static let xlWidth: CGFloat = 920
    private static let xlHeight: CGFloat = 440
    
    // MARK: - Shared Constants
    
    private static let cornerRadius: CGFloat = 16
    private static let compactPadding: CGFloat = 12
    private static let expandedPadding: CGFloat = 20
    
    // MARK: - Public API
    
    /// Determine width mode based on expansion state
    /// PRODUCTION MODEL: Binary states - compact OR properly expanded
    static func determineMode(
        itemCount: Int,
        isUserExpanded: Bool,
        isClipboardClosed: Bool
    ) -> WidthMode {
        // RULE 1: Closed/collapsed → compact pill
        if isClipboardClosed {
            return .xs
        }
        
        // RULE 2: User manually expanded → ultra wide panel
        if isUserExpanded {
            return .xl
        }
        
        // RULE 3: Opened (not closed) → ALWAYS return usable expanded size
        // Even with 0 items, show proper panel to display empty state + actions
        // This is the key fix: never return .xs when opened
        if itemCount == 0 {
            return .m  // Empty state still needs proper panel size
        }
        
        // RULE 4: Size based on content density
        switch itemCount {
        case 1...3:
            return .m  // Standard 640×360 for few items
        case 4...7:
            return .l  // Wide 760×380 for more items
        default:
            return .xl  // Ultra wide 920×440 for many items
        }
    }
    
    /// Returns appropriate metrics for a given mode
    static func metrics(for mode: WidthMode) -> Metrics {
        switch mode {
        case .xs:
            return Metrics(
                width: xsWidth,
                height: xsHeight,
                cornerRadius: cornerRadius,
                contentPadding: compactPadding,
                mode: .xs
            )
        case .s:
            return Metrics(
                width: sWidth,
                height: sHeight,
                cornerRadius: cornerRadius,
                contentPadding: compactPadding,
                mode: .s
            )
        case .m:
            return Metrics(
                width: mWidth,
                height: mHeight,
                cornerRadius: cornerRadius,
                contentPadding: compactPadding,
                mode: .m
            )
        case .l:
            return Metrics(
                width: lWidth,
                height: lHeight,
                cornerRadius: cornerRadius,
                contentPadding: expandedPadding,
                mode: .l
            )
        case .xl:
            return Metrics(
                width: xlWidth,
                height: xlHeight,
                cornerRadius: cornerRadius,
                contentPadding: expandedPadding,
                mode: .xl
            )
        }
    }
    
    /// Legacy API for backward compatibility
    @available(*, deprecated, message: "Use determineMode + metrics(for:) instead")
    static func metrics(
        isExpanded: Bool,
        itemCount: Int = 0,
        hasSelection: Bool = false,
        selectedIsImage: Bool = false
    ) -> Metrics {
        let mode = determineMode(
            itemCount: itemCount,
            isUserExpanded: isExpanded,
            isClipboardClosed: false
        )
        return metrics(for: mode)
    }
    
    /// Animation spring for size transitions (calm, no bounce)
    static let sizeTransitionSpring: (response: Double, dampingFraction: Double) = (0.28, 0.92)
}
