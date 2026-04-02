import SwiftUI

struct NowPlayingPillView: View {
    let state: IslandNowPlayingState
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onReveal: () -> Void
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // Artwork placeholder (rounded square)
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: [.purple.opacity(0.6), .blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(width: 36, height: 36)
                
                // Track info
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(state.artist)
                        .font(.system(size: 10, weight: .regular))
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Controls
                HStack(spacing: 12) {
                    Button(action: onPrevious) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .disabled(state.sourceApp.isEmpty)
                    
                    Button(action: onPlayPause) {
                        Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(state.sourceApp.isEmpty)
                    
                    Button(action: onNext) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .disabled(state.sourceApp.isEmpty)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            
            // Progress bar
            if state.duration > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                        
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * state.progress)
                            .animation(reduceMotion ? nil : .linear(duration: 0.3), value: state.progress)
                    }
                }
                .frame(height: 2)
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(radius: 8, y: 3)
        .onTapGesture {
            onReveal()
        }
    }
}

#Preview {
    NowPlayingPillView(
        state: IslandNowPlayingState(
            isPlaying: true,
            playbackRate: 1,
            title: "Song Title",
            artist: "Artist Name",
            album: "Album",
            duration: 240,
            position: 120,
            sourceApp: "Music",
            artworkData: nil
        ),
        onPlayPause: {},
        onNext: {},
        onPrevious: {},
        onReveal: {}
    )
    .frame(width: 280, height: 50)
    .padding()
}
