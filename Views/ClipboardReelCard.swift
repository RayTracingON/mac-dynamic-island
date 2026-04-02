//
//  ClipboardReelCard.swift
//  Mac灵动岛
//
//  Created by Warp Agent on 2026/01/13.
//

import SwiftUI

/// A pure UI component representing a single clipboard item in the reel.
/// Designed to be stable, jitter-free, and visually Apple-native.
struct ClipboardReelCard: View {
    let item: ClipboardItemV2
    let isSelected: Bool
    let isExpanded: Bool
    
    // Aesthetic constants
    private let cornerRadius: CGFloat = 16
    
    var body: some View {
        ZStack {
            // 1. Content Layer
            contentLayer
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            
            // 2. Selection Border (Overlay)
            // We use an overlay here for the border to ensure it doesn't affect layout
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor : Color.white.opacity(0.1), lineWidth: isSelected ? 1.5 : 1.0)
        }
        .frame(width: isExpanded ? 240 : 200, height: isExpanded ? 84 : 64)
        .background(
            // Material background
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Material.ultraThin)
                .opacity(isSelected ? 0.9 : 0.5)
        )
        // Shadow for depth
        .shadow(color: Color.black.opacity(isSelected ? 0.15 : 0.05), radius: isSelected ? 4 : 2, x: 0, y: 1)
        // Tooltip
        .help("\(item.contentType.displayName)\n\(item.previewText.prefix(50))")
    }
    
    private var contentLayer: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header: App Icon + Time + Badge
            HStack(spacing: 6) {
                Image(nsImage: item.sourceAppIcon())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
                
                Text(item.relativeTimeString)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                typeBadge
            }
            
            Spacer(minLength: 0)
            
            // Body: Preview
            if item.contentType == .image {
                HStack {
                    Spacer()
                    Image(systemName: "photo")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    Text(item.sizeInfo)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                Text(item.previewText)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.primary.opacity(0.9))
                    .lineLimit(isExpanded ? 3 : 2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            
            Spacer(minLength: 0)
        }
    }
    
    private var typeBadge: some View {
        Text(item.contentType.displayName.uppercased())
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color(nsColor: item.contentType.badgeColor).opacity(0.8))
            )
    }
}
