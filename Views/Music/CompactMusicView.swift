import SwiftUI

/// Compact music player view for notch
struct CompactMusicView: View {
    @ObservedObject var manager: MusicPlayerManager
    let namespace: Namespace.ID
    
    @State private var isHovering = false
    @State private var albumArtwork: NSImage?
    
    var body: some View {
        HStack(spacing: 12) {
            // Album Art
            Image(nsImage: manager.albumArt)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                .matchedGeometryEffect(id: "albumArt", in: namespace)
            
            // Track Info
            VStack(alignment: .leading, spacing: 2) {
                if let track = manager.currentTrack {
                    Text(track.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .matchedGeometryEffect(id: "title", in: namespace)
                    
                    Text(track.artist)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .matchedGeometryEffect(id: "artist", in: namespace)
                } else {
                    Text("No Music Playing")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: 150)
            
            Spacer()
            
            // Controls
            if manager.needsAccessibilityPermission {
                Button(action: {
                    AccessibilityHelper.shared.openAccessibilityPreferences()
                }) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button(action: {
                    manager.togglePlayPause()
                }) {
                    Image(systemName: manager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .matchedGeometryEffect(id: "playButton", in: namespace)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
