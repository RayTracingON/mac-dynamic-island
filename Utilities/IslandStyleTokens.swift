//
//  IslandStyleTokens.swift
//  Mac灵动岛
//
//  Centralized style constants for pixel-perfect macOS-native appearance
//

import SwiftUI

enum IslandStyleTokens {
    // MARK: - Core Values
    
    // Absolute Black (Hardware-match)
    static let black = Color.black
    
    // Interaction Feedback (Subtle touch response)
    static let touchOverlay = Color.white.opacity(0.12)
    
    // Text Hierarchy
    static let secondaryText = Color.white.opacity(0.64)
    static let tertiaryText = Color.white.opacity(0.4)
    
    // Accent Color (iOS System Blue)
    static let accent = Color(red: 0.0, green: 0.48, blue: 1.0)
    
    // Legacy Compatibility (Aliases to new system)
    static let textPrimary = Color.white
    static let contentBackground = Color.white.opacity(0.1) /* Fallback for legacy code */
    static let separatorOpacity: Double = 0.12
    static let surfaceStrokeWidth: CGFloat = 0.33

    // Geometry (Apple Continuous Fit)
    // Compact height is typically ~37pt on iPhone 14 Pro
    // Expanded corner radius follows the hardware curvature
    static let compactCornerRadius: CGFloat = 19
    static let expandedCornerRadius: CGFloat = 48 
    
    // MARK: - Physics (Apple Fluid Spring)
    
    // The "Island" feel comes from an overdamped-but-quick spring.
    // response: 0.55 = speed
    // damping: 0.83 = low bounce, high control (fluidity)
    static var morphAnimation: Animation {
        .spring(response: 0.55, dampingFraction: 0.825, blendDuration: 0)
    }
    
    // Snappier response for touch interactions
    static var contentAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    static var hoverAnimation: Animation {
        .spring(response: 0.25, dampingFraction: 0.6)
    }
    
    static let hoverBackgroundOpacity: Double = 0.06
    static let hoverBackgroundActiveOpacity: Double = 0.10
    
    // MARK: - Layout Constants
    
    static let compactHeight: CGFloat = 37
    static let expandedPadding: CGFloat = 22
    static let contentSpacing: CGFloat = 14
}
