//
//  ClipboardExpandedPreview.swift
//  Mac灵动岛
//
//  Created by Warp Agent on 2026/01/13.
//

import SwiftUI

/// The middle section of the expanded clipboard panel.
/// Shows rich preview of the selected item.
struct ClipboardExpandedPreview: View {
    let item: ClipboardItemV2
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Metadata
            HStack(spacing: 8) {
                Image(nsImage: item.sourceAppIcon())
                    .resizable()
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayAppName)
                        .font(.system(size: 13, weight: .semibold))
                    Text("\(item.relativeTimeString) • \(item.sizeInfo)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Type Badge (larger)
                Text(item.contentType.displayName)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(nsColor: item.contentType.badgeColor).opacity(0.2))
                    .foregroundColor(Color(nsColor: item.contentType.badgeColor))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .opacity(0.5)
            
            // Content Area
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    contentView
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black.opacity(0.03))
        }
        .background(Material.regular)
        .cornerRadius(12) // Inner radius
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch item.contentType {
        case .image:
            if let data = item.imageData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
            } else {
                Text("Image not available")
                    .foregroundColor(.secondary)
            }
            
        case .code:
            Text(item.text ?? "")
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                
        case .color:
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: item.nsColor() ?? .black))
                    .frame(width: 60, height: 60)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1)))
                
                Text(item.colorHex ?? "")
                    .font(.system(.title2, design: .monospaced))
                    .bold()
            }
            
        default:
            Text(item.text ?? item.urlString ?? item.fileDisplayName ?? "")
                .font(.body)
                .textSelection(.enabled)
        }
    }
}
