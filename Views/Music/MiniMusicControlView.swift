import Combine
import SwiftUI

/// Minimal music control bar for notch
struct MiniMusicControlView: View {
    @ObservedObject var manager: MusicPlayerManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Tiny Album Art
            Image(nsImage: manager.albumArt)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // Track Name (Marquee)
            if let track = manager.currentTrack {
                IslandMarqueeText(
                    text: .constant("\(track.title) • \(track.artist)"),
                    font: .system(size: 11),
                    frameWidth: 120
                )
                .foregroundColor(.primary)
            }
            
            // Tiny Controls
            HStack(spacing: 8) {
                Button(action: { manager.previous() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { manager.togglePlayPause() }) {
                    Image(systemName: manager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { manager.next() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
}
