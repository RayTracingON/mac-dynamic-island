import SwiftUI

struct DebugHUD: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var activityCenter: ActivityCenter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            statusSectionView
            activitySectionView
            eventSectionView
        }
        .padding(8)
        .background(Color.black.opacity(0.8))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var header: some View {
        Text("🔍 DEBUG HUD")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
        
        Divider().background(Color.white.opacity(0.3))
    }
    
    @ViewBuilder
    private var statusSectionView: some View {
        HStack {
            Text("Visibility:")
                .font(.system(size: 9))
                .foregroundColor(.gray)
            Text(appState.isOverlayVisible ? "VISIBLE" : "HIDDEN")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(appState.isOverlayVisible ? .green : .red)
        }
        
        HStack {
            Text("Reason:")
                .font(.system(size: 9))
                .foregroundColor(.gray)
            Text("\(String(describing: appState.visibilityReason))")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.cyan)
        }
        
        HStack {
            Text("Mode:")
                .font(.system(size: 9))
                .foregroundColor(.gray)
            Text(appState.overlayMode == .compact ? "PILL" : "PANEL")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.orange)
        }
    }
    
    @ViewBuilder
    private var activitySectionView: some View {
        HStack {
            Text("Activities:")
                .font(.system(size: 9))
                .foregroundColor(.gray)
            Text("\(activityCenter.activities.count)")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.yellow)
        }
        
        if let topActivity = activityCenter.topActivity {
            HStack {
                Text("Top:")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                Text("\(topActivity.kind.rawValue)")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.green)
            }
        }
    }
    
    @ViewBuilder
    private var eventSectionView: some View {
        Divider().background(Color.white.opacity(0.3))
        
        HStack {
            Text("Last Event:")
                .font(.system(size: 9))
                .foregroundColor(.gray)
            Text(appState.lastEventDescription)
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        
        HStack {
            Text("Timestamp:")
                .font(.system(size: 9))
                .foregroundColor(.gray)
            Text(appState.lastEventTimestamp)
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

#Preview {
    DebugHUD()
        .environmentObject(AppState())
        .environmentObject(ActivityCenter.shared)
        .frame(width: 200)
}
