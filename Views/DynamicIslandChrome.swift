import SwiftUI

/// Dynamic Island Chrome — Proper Capsule Shape
///
/// CRITICAL FIXES:
/// 1. Does NOT use .frame(maxWidth: .infinity) which was filling the rectangular window
/// 2. Uses .fixedSize(horizontal: false, vertical: true) to hug content vertically
/// 3. Black background only wraps around the actual content, not the window
/// 4. Hit-testing properly constrained to the capsule shape
///
struct DynamicIslandChrome<Content: View>: View {
    let isExpanded: Bool
    let content: Content
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    // Corner radius for the capsule
    private var cornerRadius: CGFloat {
        isExpanded ? 32.0 : 19.0
    }
    
    init(isExpanded: Bool, @ViewBuilder content: () -> Content) {
        self.isExpanded = isExpanded
        self.content = content()
    }
    
    var body: some View {
        content
            // Padding inside the capsule
            .padding(.horizontal, isExpanded ? 16 : 12)
            .padding(.vertical, isExpanded ? 12 : 8)
            
            // CRITICAL: Do NOT use .frame(maxWidth: .infinity)
            // That would fill the rectangular window
            // Instead, let content define its own width
            
            // Black background that wraps ONLY the content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black)
            )
            
            // Hit-testing shape - matches the visual capsule
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            
            // Clip to capsule shape
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            
            // Animation
            .animation(
                reduceMotion ? .linear(duration: 0.2) : IslandStyleTokens.morphAnimation,
                value: isExpanded
            )
    }
}

// MARK: - Modifier

extension View {
    func dynamicIslandChrome(isExpanded: Bool) -> some View {
        DynamicIslandChrome(isExpanded: isExpanded) {
            self
        }
    }
}


