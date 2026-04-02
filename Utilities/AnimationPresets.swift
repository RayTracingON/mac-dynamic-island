//
//  AnimationPresets.swift
//  Mac灵动岛
//
//  ============================================================
//  100% FRAME-PERFECT EXTRACTION FROM BORING.NOTCH SOURCE
//  ============================================================
//  All parameters below are EXACT values from the original codebase.
//  Source files cited for each parameter.
//

import SwiftUI

struct IslandAnimations {
    
    // ============================================================
    // MARK: - CORE ANIMATION SPRINGS (From Boring.notch)
    // ============================================================
    
    /// PRIMARY ANIMATION - Used for all size/layout transitions
    /// Source: boring.notch/boringNotch/animations/drop.swift lines 19-24
    /// 
    /// macOS 14+: Uses `.bouncy(duration: 0.4)` - this creates the signature "alive" feel
    /// Fallback: Custom bezier curve (0.16, 1, 0.3, 1) for older macOS
    static var primaryAnimation: Animation {
        if #available(macOS 14.0, *) {
            return Animation.spring(.bouncy(duration: 0.4))
        } else {
            return Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.7)
        }
    }
    
    /// INTERACTIVE SPRING - The "magnetic" shared spring
    /// Source: boring.notch/boringNotch/ContentView.swift line 41
    /// 
    /// Parameters: response=0.38, dampingFraction=0.8, blendDuration=0
    /// This is used for ALL movement/resizing to avoid conflicting animations
    /// The 0.8 damping creates slight bounce without feeling uncontrolled
    static let interactiveSpring: Animation = .interactiveSpring(
        response: 0.38,
        dampingFraction: 0.8,
        blendDuration: 0
    )
    
    /// OPEN ANIMATION - Slightly slower spring for expansion
    /// Source: boring.notch/boringNotch/ContentView.swift line 123
    /// 
    /// Parameters: response=0.42, dampingFraction=0.8
    /// Used when notch transitions from closed -> open
    static let openAnimation: Animation = .spring(
        response: 0.42,
        dampingFraction: 0.8,
        blendDuration: 0
    )
    
    /// CLOSE ANIMATION - Critical damping for controlled return
    /// Source: boring.notch/boringNotch/ContentView.swift line 124
    /// 
    /// Parameters: response=0.45, dampingFraction=1.0
    /// dampingFraction=1.0 means NO oscillation - settles without bounce
    /// Used when notch transitions from open -> closed
    static let closeAnimation: Animation = .spring(
        response: 0.45,
        dampingFraction: 1.0,
        blendDuration: 0
    )
    
    // ============================================================
    // MARK: - COMPONENT-SPECIFIC ANIMATIONS
    // ============================================================
    
    /// SLIDER DRAG SPRING
    /// Source: boring.notch/boringNotch/components/Notch/NotchHomeView.swift line 575
    /// 
    /// Parameters: response=0.35, dampingFraction=0.7
    /// Snappier than main springs for precise control feedback
    static let sliderDragSpring: Animation = .spring(
        response: 0.35,
        dampingFraction: 0.7
    )
    
    /// BUTTON BOUNCE SPRING
    /// Source: boring.notch/boringNotch/extensions/Button+Bouncing.swift line 24
    /// 
    /// Parameters: response=0.3, dampingFraction=0.3, blendDuration=0.3
    /// Very low damping = very bouncy. Creates the playful button feel.
    static let buttonBounceSpring: Animation = .spring(
        response: 0.3,
        dampingFraction: 0.3,
        blendDuration: 0.3
    )
    
    /// HOVER SELECTION SPRING
    /// Source: boring.notch/boringNotch/components/Onboarding/MusicControllerSelectionView.swift line 88
    /// 
    /// Parameters: response=0.3, dampingFraction=0.6
    /// Balanced spring for hover/selection state changes
    static let hoverSelectionSpring: Animation = .spring(
        response: 0.3,
        dampingFraction: 0.6
    )
    
    /// DROP ZONE SPRING
    /// Source: boring.notch/boringNotch/components/Shelf/Views/FileShareView.swift line 84
    /// 
    /// Parameters: response=0.36, dampingFraction=0.7
    /// Used for drop zone targeting visual feedback
    static let dropZoneSpring: Animation = .spring(
        response: 0.36,
        dampingFraction: 0.7
    )
    
    // ============================================================
    // MARK: - SMOOTH ANIMATIONS
    // ============================================================
    
    /// SMOOTH - Standard smooth for state changes
    /// Source: various files using .smooth
    /// Note: .smooth requires macOS 14+, fallback to easeInOut
    static var smooth: Animation {
        if #available(macOS 14.0, *) {
            return .smooth
        } else {
            return .easeInOut(duration: 0.25)
        }
    }
    
    /// SMOOTH WITH DURATION - For system event indicators
    /// Source: boring.notch/boringNotch/components/Live activities/SystemEventIndicatorModifier.swift line 136
    /// Note: .smooth(duration:) requires macOS 14+
    static var smoothDuration: Animation {
        if #available(macOS 14.0, *) {
            return .smooth(duration: 0.3)
        } else {
            return .easeInOut(duration: 0.3)
        }
    }
    
    // ============================================================
    // MARK: - EASE ANIMATIONS
    // ============================================================
    
    /// FAST EASE - For quick toggles (volume slider, etc)
    /// Source: boring.notch/boringNotch/components/Notch/NotchHomeView.swift line 342
    static let fastEaseInOut: Animation = .easeInOut(duration: 0.12)
    
    /// MEDIUM EASE - For control toggles
    /// Source: boring.notch/boringNotch/components/Notch/NotchHomeView.swift line 385
    static let mediumEaseInOut: Animation = .easeInOut(duration: 0.2)
    
    /// ONBOARDING EASE - For step transitions
    /// Source: boring.notch/boringNotch/components/Onboarding/OnboardingView.swift line 33
    static let onboardingEase: Animation = .easeInOut(duration: 0.6)
    
    // ============================================================
    // MARK: - LEGACY ALIASES (for backward compatibility)
    // ============================================================
    
    /// Alias: fluidSpring -> Uses interpolatingSpring for smooth size transitions
    /// ============================================
    /// 核心修正: stiffness: 300, damping: 22 (Boring Notch 精确参数)
    /// 这是实现"果冻感"的关键参数
    /// ============================================
    static let fluidSpring: Animation = .interpolatingSpring(stiffness: 300, damping: 22)
    
    /// 高品质弹簧 - 用于展开/收起的主动画
    static let premiumSpring: Animation = .interpolatingSpring(
        stiffness: 300,
        damping: 22,
        initialVelocity: 0
    )
    
    /// Alias: contentSpring -> For internal content transitions
    static let contentSpring: Animation = .spring(response: 0.35, dampingFraction: 0.75)
    
    /// Alias: hoverSpring -> Fast response hover feedback
    static let hoverSpring: Animation = .spring(response: 0.2, dampingFraction: 0.7)
    
    /// Alias: smoothOpacity -> Quick opacity fades
    static let smoothOpacity: Animation = .easeInOut(duration: 0.15)
    
    // ============================================================
    // MARK: - UTILITY FUNCTIONS
    // ============================================================
    
    /// Staggered animation for list items
    static func staggered(index: Int) -> Animation {
        return contentSpring.delay(Double(index) * 0.025)
    }
    
    // ============================================================
    // MARK: - GESTURE PHYSICS CONSTANTS
    // Source: boring.notch/boringNotch/ContentView.swift lines 560-608
    // ============================================================
    
    /// Default gesture sensitivity
    /// Source: Defaults[.gestureSensitivity] - typically 20-30
    static let gestureSensitivity: CGFloat = 20
    
    /// Gesture progress multiplier
    /// Formula: translation / sensitivity * 20
    static let gestureProgressMultiplier: CGFloat = 20
    
    /// Calculate gesture scale from progress
    /// Source: ContentView.swift lines 85-88
    /// Formula: 1.0 + gestureProgress * 0.01, clamped to min 0.6
    static func gestureScale(from progress: CGFloat) -> CGFloat {
        guard progress != 0 else { return 1.0 }
        let scaleFactor = 1.0 + progress * 0.01
        return max(0.6, scaleFactor)
    }
    
    /// Calculate opacity during gesture
    /// Source: ContentView.swift line 296
    /// Formula: 1.0 - min(abs(progress) * 0.1, 0.3)
    static func gestureOpacity(from progress: CGFloat) -> CGFloat {
        guard progress != 0 else { return 1.0 }
        return 1.0 - min(abs(progress) * 0.1, 0.3)
    }
}

// MARK: - Hover Modifier

struct IslandHoverEffect: ViewModifier {
    var scale: CGFloat = 1.03  // boring.notch 风格的微妙缩放
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(IslandAnimations.hoverSpring, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func islandHoverEffect(scale: CGFloat = 1.03) -> some View {
        self.modifier(IslandHoverEffect(scale: scale))
    }
}
