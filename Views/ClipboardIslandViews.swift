import SwiftUI

// MARK: - Clipboard Toast (Copy Confirmation State)

struct ClipboardToastView: View {
    let item: ClipboardHistoryStore.ClipboardItem
    
    var body: some View {
        HStack(spacing: 12) {
            // 1. App Icon / Leading Visual
            if item.type == .image, let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 22, height: 22)
                    .clipShape(Circle())
            } else if item.sourceBundleIdentifier != nil {
                Image(nsImage: item.sourceIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(IslandStyleTokens.accent)
            }
            
            // 2. Text Content - MUST BE VISIBLE (white on black)
            VStack(alignment: .leading, spacing: 2) {
                Text("Copied from " + (item.sourceAppName ?? "App"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white) // CRITICAL: Visible on black
                
                Text(item.preview)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 3. Trailing Status
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(minHeight: 44) // Ensure minimum touch target
        .contentShape(Rectangle()) // Entire area is tappable
        
        #if DEBUG
        .background(Color.blue.opacity(0.1)) // DEBUG: Verify zone visibility
        #endif
    }
}

// MARK: - Clipboard Picker (Horizontal Reel)

struct ClipboardPickerView: View {
    @EnvironmentObject private var clipboardStore: ClipboardHistoryStore
    let onSelectItem: (ClipboardHistoryStore.ClipboardItem) -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Clipboard History")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white) // CRITICAL: Visible
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Horizontal Reel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(clipboardStore.displayableItems) { item in
                        ClipboardCardView(item: IslandClipItem(from: item)) {
                            onSelectItem(item)
                        }
                        .contentShape(Rectangle()) // Each card is tappable
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .frame(height: 140)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle()) // Entire picker is interactive
        
        #if DEBUG
        .background(Color.green.opacity(0.1)) // DEBUG: Verify zone visibility
        #endif
    }
}
