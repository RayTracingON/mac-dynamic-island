import SwiftUI

struct DragTargetOverlay: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        RoundedRectangle(cornerRadius: 25, style: .continuous)
            .strokeBorder(
                style: StrokeStyle(
                    lineWidth: 2,
                    lineCap: .round,
                    dash: [8, 6]
                )
            )
            .foregroundColor(.blue.opacity(0.8))
            .background(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(.blue.opacity(0.05))
            )
            .scaleEffect(reduceMotion ? 1.0 : 1.02)
            .animation(
                reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7),
                value: true
            )
    }
}

#Preview {
    DragTargetOverlay()
        .frame(width: 300, height: 60)
        .padding()
}
