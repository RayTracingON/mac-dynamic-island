//
//  DebugInteractionOverlay.swift
//  Mac 灵动岛
//
//  DEBUG-only utilities for visualizing hit-test boundaries and interactive regions
//

import SwiftUI

#if DEBUG
extension View {
    /// Adds a colored border and label overlay to visualize interactive regions
    /// Only compiled in DEBUG builds
    /// Also logs which region received a tap, without stealing events from controls.
    func debugInteractionOverlay(label: String, color: Color) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(color.opacity(0.5), lineWidth: 2)
                    .allowsHitTesting(false)
            )
            .overlay(alignment: .topLeading) {
                Text(label)
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                    .padding(2)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(2)
                    .padding(2)
                    .allowsHitTesting(false)
            }
            .simultaneousGesture(TapGesture().onEnded {
                print("[DEBUG][HitTest] region=\(label)")
            })
    }
}
#else
// Production no-op
extension View {
    func debugInteractionOverlay(label: String, color: Color) -> some View {
        self
    }
}
#endif
