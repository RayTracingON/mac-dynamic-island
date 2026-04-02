import SwiftUI

/// Music player view with lyrics display
struct MusicWithLyricsView: View {
    @ObservedObject var manager: MusicPlayerManager
    
    var body: some View {
        HStack(spacing: 24) {
            // Album Art (Proportional & Fixed)
            ZStack {
                // Background glow
                Circle()
                    .fill(Color(manager.albumArt.averageColor).opacity(0.3))
                    .blur(radius: 40)
                    .frame(width: 120, height: 120)
                
                Image(nsImage: manager.albumArt)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.4), radius: 15, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            }
            .frame(width: 160, height: 160)
            
            // Info and Controls Column
            VStack(alignment: .leading, spacing: 16) {
                // Track Metadata
                VStack(alignment: .leading, spacing: 4) {
                    if let track = manager.currentTrack {
                        Text(track.title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(track.artist)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("No Music Playing")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progress Slider (The New Improved One)
                MusicSliderContainer(manager: manager)
                    .padding(.vertical, 4)
                
                // Main Playback Controls
                HStack(spacing: 32) {
                    Spacer()
                    
                    Button(action: { manager.previous() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 20))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { manager.togglePlayPause() }) {
                        Image(systemName: manager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 48))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { manager.next() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                
                // Lyrics Preview (Optional/Bottom)
                if let lyrics = manager.currentTrack?.lyrics, !lyrics.isEmpty {
                    Text(manager.lyricLine(at: manager.currentTime))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.accentColor)
                        .lineLimit(1)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .id(manager.lyricLine(at: manager.currentTime))
                }
            }
        }
        .padding(24)
    }
    
    // Note: Removed local updateCurrentLyric and albumArtwork as they are now handled by manager sync
}

// Extension to MusicPlayerManager to help with lyrics in UI
extension MusicPlayerManager {
    func lyricLine(at time: Double) -> String {
        // This is a bridge to the private musicManager.lyricLine
        // Since we are already in the same project, we can just call it if it was public or recreate it
        return MusicManager.shared.lyricLine(at: time)
    }
}

// MARK: - Lyric Line Model

extension MusicTrack {
    struct LyricLine {
        let timestamp: TimeInterval
        let text: String
    }
}

