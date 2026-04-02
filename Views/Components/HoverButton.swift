//
//  HoverButton.swift
//  boringNotch
//
//  Created by Kraigo on 04.09.2024.
//

import SwiftUI

struct HoverButton: View {
    var icon: String
    var iconColor: Color = .white
    var scale: Image.Scale = .medium
    var action: () -> Void
    var contentTransition: ContentTransition = .symbolEffect
    
    @State private var isHovering = false

    var body: some View {
        let size = CGFloat(scale == .large ? 44 : 36)
        let iconSize = scale == .large ? CGFloat(20) : CGFloat(16)
        
        Button(action: {
            action()
            // Haptic feedback
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }) {
            ZStack {
                // Background Highlight
                Capsule()
                    .fill(isHovering ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
                    .frame(width: size, height: size)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(isHovering ? 0.15 : 0.05), lineWidth: 0.5)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundColor(isHovering ? .white : iconColor.opacity(0.8))
                    .contentTransition(contentTransition)
            }
        }
        .buttonStyle(IslandButtonStyle())
        .onHover { hovering in
            withAnimation(IslandDesign.Motion.hoverAnimation) {
                isHovering = hovering
            }
        }
    }
}
