import SwiftUI

/// A premium, interactive slider for music playback, inspired by Apple's design.
struct IslandMusicSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var accentColor: Color = .accentColor
    var onEditingChanged: (Bool) -> Void = { _ in }
    
    @State private var isDragging = false
    @State private var dragValue: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height: CGFloat = isDragging ? 10 : 4
            let progress = CGFloat((isDragging ? dragValue : value) / (range.upperBound > 0 ? range.upperBound : 1))
            
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: height)
                
                // Progress
                Capsule()
                    .fill(accentColor)
                    .frame(width: max(0, min(width * progress, width)), height: height)
                
                // Knob (only show when dragging)
                if isDragging {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .offset(x: width * progress - 7)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
            }
            .contentShape(Rectangle())
            .frame(height: 20)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            isDragging = true
                            onEditingChanged(true)
                        }
                        let pct = Double(gesture.location.x / width)
                        dragValue = min(max(pct * range.upperBound, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        value = dragValue
                        isDragging = false
                        onEditingChanged(false)
                    }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
        }
        .frame(height: 20)
    }
}

struct MusicSliderContainer: View {
    @ObservedObject var manager: MusicPlayerManager
    
    @State private var isSeeking = false
    @State private var seekValue: Double = 0
    
    var body: some View {
        VStack(spacing: 4) {
            IslandMusicSlider(
                value: Binding(
                    get: { isSeeking ? seekValue : manager.currentTime },
                    set: { newValue in
                        seekValue = newValue
                        if !isSeeking {
                            manager.seek(to: newValue)
                        }
                    }
                ),
                range: 0...(manager.currentTrack?.duration ?? 1),
                accentColor: .accentColor,
                onEditingChanged: { editing in
                    isSeeking = editing
                    if !editing {
                        // ✅ 拖拽结束后才 seek
                        manager.seek(to: seekValue)
                    } else {
                        seekValue = manager.currentTime
                    }
                }
            )
            
            HStack {
                Text(formatTime(isSeeking ? seekValue : manager.currentTime))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("-" + formatTime(max(0, (manager.currentTrack?.duration ?? 0) - (isSeeking ? seekValue : manager.currentTime))))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
