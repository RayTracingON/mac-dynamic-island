import Combine
import SwiftUI

/// Album art view - PERFORMANCE OPTIMIZED
/// ✅ 移除了背景光晕、旋转动画和脉冲效果，减少 GPU 和 CPU 占用
struct AlbumArtView: View {
    let artwork: NSImage?
    let size: CGFloat
    let isPlaying: Bool
    
    var body: some View {
        ZStack {
            // Main Album Art
            if let artwork = artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.1)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: size * 0.1)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: size * 0.4))
                            .foregroundColor(.white.opacity(0.3))
                    )
            }
            
            // Play Indicator - ✅ 保留但简化
            if isPlaying {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: size * 0.12, height: size * 0.12)
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.system(size: size * 0.06))
                            .foregroundColor(.white)
                    )
                    .offset(x: size * 0.35, y: -size * 0.35)
            }
        }
    }
}
