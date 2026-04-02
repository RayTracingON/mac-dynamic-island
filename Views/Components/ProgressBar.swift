import Combine
import SwiftUI

/// Custom progress bar component
struct ProgressBar: View {
    let value: Double
    var height: CGFloat = 4
    var color: Color = .accentColor
    var backgroundColor: Color = Color.secondary.opacity(0.2)
    var showLabel: Bool = false
    var animated: Bool = true
    
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(backgroundColor)
                        .frame(height: height)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(color)
                        .frame(width: geometry.size.width * clampedValue, height: height)
                        .animation(animated ? .spring(response: 0.3) : .none, value: value)
                }
            }
            .frame(height: height)
            
            if showLabel {
                Text("\(Int(clampedValue * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var clampedValue: Double {
        return max(0, min(1, value))
    }
}

/// Circular progress indicator
struct CircularProgress: View {
    let value: Double
    var size: CGFloat = 40
    var lineWidth: CGFloat = 4
    var color: Color = .accentColor
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: clampedValue)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.3), value: value)
        }
        .frame(width: size, height: size)
    }
    
    private var clampedValue: Double {
        return max(0, min(1, value))
    }
}

#Preview {
    VStack(spacing: 40) {
        VStack(spacing: 16) {
            ProgressBar(value: 0.3)
            ProgressBar(value: 0.6, color: .blue, showLabel: true)
            ProgressBar(value: 0.9, height: 8, color: .green)
        }
        .padding()
        
        HStack(spacing: 30) {
            CircularProgress(value: 0.25)
            CircularProgress(value: 0.5, color: .blue)
            CircularProgress(value: 0.75, size: 60, lineWidth: 6, color: .green)
        }
    }
    .frame(width: 400, height: 400)
}
