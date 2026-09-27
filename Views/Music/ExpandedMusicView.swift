import SwiftUI
import Combine
import UniformTypeIdentifiers

struct ExpandedMusicView: View {
    @ObservedObject var musicManager: MusicManager
    var animation: Namespace.ID

    @State private var isSeeking = false
    @State private var seekTime: Double = 0
    @State private var lastSongTitle: String = ""

    /// Side of the artwork, as tall as the text beside it: from the top of the title down to the progress bar,
    /// with room for two lines of lyrics in between
    private static let artSize: CGFloat = 92
    /// The play button, the tallest of the controls
    private static let playButtonSize: CGFloat = 34
    private static let controlsSpacing: CGFloat = 8
    private static let topPadding: CGFloat = 12
    private static let bottomPadding: CGFloat = 12
    /// Height of the whole module, which NotchMetrics gives the Music tab
    static let height = topPadding + artSize + controlsSpacing + playButtonSize + bottomPadding

    var body: some View {
        VStack(spacing: Self.controlsSpacing) {
            HStack(alignment: .top, spacing: 16) {
                // 💿 ALBUM ART, level with the title
                albumArtView
                
                // 📝 TRACK INFO & LYRICS & PROGRESS
                VStack(alignment: .leading, spacing: 0) {
                    // Title & Artist
                    VStack(alignment: .leading, spacing: 2) {
                        Text(musicManager.songTitle.isEmpty ? "Not Playing" : musicManager.songTitle)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(musicManager.artistName.isEmpty ? "Select a track" : musicManager.artistName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    
                    // 🎤 LYRICS: up to two lines between the artist and the progress bar
                    if !musicManager.currentLyrics.isEmpty {
                        LyricsView(musicManager: musicManager)
                            .padding(.top, 4)
                    }
                    
                    Spacer(minLength: 4)

                    // ⏱ PROGRESS STRIP, level with the bottom of the artwork
                    progressStrip
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: Self.artSize)
            }

            // 🎮 MEDIA CONTROLS, centered in the module rather than under the text
            mediaControls
        }
        .padding(.horizontal, 20)
        .padding(.top, Self.topPadding)
        .padding(.bottom, Self.bottomPadding)
        .onChange(of: musicManager.songTitle) { oldTitle, newTitle in
            // ✅ 歌曲切换时重置拖拽状态
            if newTitle != oldTitle && !oldTitle.isEmpty {
                isSeeking = false
                seekTime = 0
            }
            lastSongTitle = newTitle
        }
    }
    
    private var albumArtView: some View {
        Button(action: { selectCustomAlbumArt() }) {
            AlbumArtwork(musicManager: musicManager)
                .matchedGeometryEffect(id: "album_art", in: animation)
                .frame(width: Self.artSize, height: Self.artSize)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    
    private var progressStrip: some View {
        let duration = max(0, musicManager.songDuration)
        let displayTime = isSeeking ? seekTime : musicManager.currentDisplayTime
        let durationText = duration > 0 ? formatTime(duration) : "--:--"

        // The times either side of the bar rather than on a row of their own
        return HStack(spacing: 8) {
            // As wide as the duration, so the bar keeps its length while the time counts up
            Text(durationText)
                .hidden()
                .overlay(alignment: .leading) {
                    Text(formatTime(displayTime))
                        .fixedSize()
                }

            GeometryReader { geo in
                let progress = duration > 0 ? min(1.0, max(0.0, displayTime / duration)) : 0
                let barHeight: CGFloat = 4

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: barHeight)

                    if duration > 0 {
                        Capsule()
                            .fill(Color.white)
                            .frame(width: max(0, geo.size.width * progress), height: barHeight)
                    }
                }
                // The bar runs through the middle of a taller strip, which is easier to grab
                .frame(width: geo.size.width, height: geo.size.height)
                .contentShape(Rectangle())
                .gesture(
                    duration > 0
                    ? DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            let width = max(CGFloat(1), geo.size.width)
                            let pct = min(1.0, max(0.0, Double(gesture.location.x / width)))
                            seekTime = pct * duration
                            if !isSeeking { 
                                isSeeking = true 
                            }
                        }
                        .onEnded { _ in
                            let target = min(max(0, seekTime), duration)
                            musicManager.seek(to: target)
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(50))
                                isSeeking = false
                            }
                        }
                    : nil
                )
            }
            .frame(height: 12)

            Text(durationText)
        }
        .font(.system(size: 9, design: .monospaced))
        .foregroundColor(.white.opacity(0.4))
    }
    
    private var mediaControls: some View {
        HStack(spacing: 20) {
            controlButton(icon: "backward.fill") { musicManager.previousTrack() }
            
            Button(action: { musicManager.togglePlay() }) {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: Self.playButtonSize, height: Self.playButtonSize)
                    .overlay(
                        Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            .buttonStyle(.plain)
            
            controlButton(icon: "forward.fill") { musicManager.nextTrack() }
        }
        // Centered in the whole module: previous and next are as wide, so the play button sits in the middle
        .frame(maxWidth: .infinity)
    }
    
    private func controlButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite && seconds >= 0 else { return "0:00" }
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
    
    /// 📸 选择自定义专辑封面
    private func selectCustomAlbumArt() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        panel.message = "选择一张图片作为专辑封面"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            Task { @MainActor in
                if let image = NSImage(contentsOf: url) {
                    musicManager.albumArt = image
                    musicManager.usingAppIconForArtwork = false
                }
            }
        }
    }
}

// MARK: - Album Artwork
/// The cover, filling the square it's given. The placeholder note isn't a cover: filling the square would blow it up
/// and crop it, so it sits whole in the middle of a tile instead
struct AlbumArtwork: View {
    @ObservedObject var musicManager: MusicManager

    var body: some View {
        if musicManager.hasPlaceholderArtwork {
            GeometryReader { geo in
                Image(systemName: "music.note")
                    .font(.system(size: min(geo.size.width, geo.size.height) * 0.4, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .background(Color.white.opacity(0.1))
        } else {
            Image(nsImage: musicManager.albumArt)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }
}

// MARK: - Lyrics View
struct LyricsView: View {
    @ObservedObject var musicManager: MusicManager
    
    // Only as tall as its one or two lines, so it sits right below the artist
    var body: some View {
        if !musicManager.syncedLyrics.isEmpty {
            // Synced Lyrics
            let currentLine = musicManager.lyricLine(at: musicManager.currentDisplayTime)
            Text(currentLine.isEmpty ? "..." : currentLine)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
                .id("synced_\(currentLine)")
        } else {
            // Static Lyrics: the first two lines
            Text(cleanLyrics(musicManager.currentLyrics))
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func cleanLyrics(_ text: String) -> String {
        // Remove time tags if any remain, though fetcher should strip them
        return text.replacingOccurrences(of: "\\[.*?\\]", with: "", options: .regularExpression)
                   .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
