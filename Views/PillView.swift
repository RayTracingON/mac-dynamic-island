import SwiftUI
import UniformTypeIdentifiers

struct PillView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var activityCenter: ActivityCenter
    @EnvironmentObject private var nowPlayingManager: NowPlayingManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    // Derive current pill type for smooth transitions
    private var currentPillType: String {
        if nowPlayingManager.currentState.hasContent {
            return "nowPlaying"
        } else if activityCenter.topActivity != nil {
            return "activity"
        } else {
            return "default"
        }
    }

    var body: some View {
        Group {
            // Priority 1: Now Playing (if active)
            if nowPlayingManager.currentState.hasContent {
                NowPlayingPillView(
                    state: nowPlayingManager.currentState,
                    onPlayPause: { nowPlayingManager.playPause() },
                    onNext: { nowPlayingManager.nextTrack() },
                    onPrevious: { nowPlayingManager.previousTrack() },
                    onReveal: { nowPlayingManager.revealSourceApp() }
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                    removal: .opacity
                ))
            }
            // Priority 2: Activities (clipboard, drop, timer)
            else if let topActivity = activityCenter.topActivity {
                ActivityPillView(activity: topActivity)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity
                    ))
            }
            // Priority 3: Default pill
            else {
                defaultPill
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity
                    ))
            }
        }
        .animation(reduceMotion ? .linear(duration: 0.15) : .easeOut(duration: 0.25), value: currentPillType)
        .id(activityCenter.activities.count) // Force re-render on activity changes
        .onTapGesture {
            // Click in compact mode activates overlay (idle/armed → active)
            withAnimation(reduceMotion ? Animation.linear(duration: 0.15) : Animation.easeInOut(duration: 0.3)) {
                appState.activateOverlay(reason: .userExpanded)
            }
        }
    }
    
    private var defaultPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.system(size: 14, weight: .semibold))
                .opacity(0.8)

            Spacer(minLength: 4)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(radius: 8, y: 3)
    }
}

#Preview {
    PillView()
        .environmentObject(AppState())
        .environmentObject(ActivityCenter.shared)
        .environmentObject(NowPlayingManager())
        .frame(width: 280, height: 50)
        .padding()
}
