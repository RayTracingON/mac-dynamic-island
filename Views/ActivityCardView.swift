import SwiftUI

struct ActivityCardView: View {
    let activity: Activity
    let onAction: (String) -> Void
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: activity.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.title)
                        .font(.system(size: 13, weight: .semibold))
                    Text(activity.message)
                        .font(.system(size: 11, weight: .regular))
                        .opacity(0.6)
                }
                
                Spacer()
                
                if let progress = activity.progress {
                    ProgressView(value: progress)
                        .frame(width: 32)
                }
            }
            
            // Actions
            if !activity.actions.isEmpty {
                HStack(spacing: 8) {
                    ForEach(activity.actions) { action in
                        Button(action: { onAction(action.action) }) {
                            Text(action.title)
                                .font(.system(size: 11, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// #Preview {
//     let activity = Activity.drop(itemCount: 3)
//     ActivityCardView(activity: activity) { action in
//         print("Action: \(action)")
//     }
//     .padding()
// }
