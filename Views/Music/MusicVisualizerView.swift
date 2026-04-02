import SwiftUI

/// Music visualizer - PERFORMANCE OPTIMIZED (light static display only)
/// ✅ 移除了 Timer 和 repeatForever 动画，大大减少 CPU 占用
struct MusicVisualizerView: View {
    let isPlaying: Bool
    let barCount: Int
    let height: CGFloat
    
    init(isPlaying: Bool, barCount: Int = 5, height: CGFloat = 20) {
        self.isPlaying = isPlaying
        self.barCount = barCount
        self.height = height
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor.opacity(isPlaying ? 0.8 : 0.3))
                    .frame(width: 3, height: height * staticHeight(for: index))
            }
        }
        .frame(height: height)
        .animation(.easeInOut(duration: 0.3), value: isPlaying)
    }
    
    // ✅ 静态显示：每个 bar 有不同高度，但不再持续动画
    private func staticHeight(for index: Int) -> CGFloat {
        let heights: [CGFloat] = [0.4, 0.7, 0.9, 0.6, 0.5]
        return heights[index % heights.count]
    }
}
