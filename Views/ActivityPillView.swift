import SwiftUI

struct ActivityPillView: View {
    let activity: Activity
    @EnvironmentObject var appState: AppState
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: activity.iconName)
                .font(.system(size: 14, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(activity.title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Text(activity.message)
                    .font(.system(size: 10, weight: .regular))
                    .opacity(0.7)
                    .lineLimit(1)
            }
            
            if let progress = activity.progress {
                Spacer()
                ProgressView(value: progress)
                    .scaleEffect(x: 1, y: 0.8, anchor: .center)
                    .frame(width: 24)
            }
            
            Spacer(minLength: 4)
            
            // Dismiss button
            Button(action: {
                Task { @MainActor in
                    ActivityCenter.shared.dismiss(activity.id)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .opacity(0.6)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        .shadow(radius: 8, y: 3)
    }
}

// #Preview {
//     let activity = Activity.clipboard(message: "Path copied")
//     ActivityPillView(activity: activity)
//         .environmentObject(AppState())
//         .frame(width: 280)
//         .padding()
// }
