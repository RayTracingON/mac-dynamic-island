import SwiftUI

/// Main onboarding flow view
struct OnboardingView: View {
    @State private var currentPage = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.dismiss) private var dismiss
    
    private let pages = 4
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    WelcomeView()
                        .tag(0)
                    
                    FeaturesView()
                        .tag(1)
                    
                    PermissionsView()
                        .tag(2)
                    
                    CompletionView(onComplete: completeOnboarding)
                        .tag(3)
                }
                .tabViewStyle(.automatic)
                
                // Page indicator and navigation
                HStack(spacing: 16) {
                    // Previous button
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    // Page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pages, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.accentColor : Color.secondary)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Spacer()
                    
                    // Next/Done button
                    if currentPage < pages - 1 {
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Material.ultraThinMaterial)
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        dismiss()
    }
}

// MARK: - Welcome View

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "macwindow")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .symbolEffect(.bounce, value: true)
            
            Text("Welcome to Mac灵动岛")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("A beautiful menu bar utility that brings dynamic island features to your Mac")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 60)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Features View

struct FeaturesView: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("Features")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 24) {
                FeatureRow(
                    icon: "music.note",
                    title: "Music Control",
                    description: "Control Apple Music, Spotify, and more"
                )
                
                FeatureRow(
                    icon: "tray.fill",
                    title: "Smart Shelf",
                    description: "Quick access to your files and folders"
                )
                
                FeatureRow(
                    icon: "calendar",
                    title: "Calendar Integration",
                    description: "See your upcoming events at a glance"
                )
                
                FeatureRow(
                    icon: "battery.100",
                    title: "System Monitoring",
                    description: "Track battery, volume, and brightness"
                )
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.accentColor)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Permissions View

struct PermissionsView: View {
    @ObservedObject var calendarManager = CalendarManager.shared
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Permissions")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("We need your permission to provide the best experience")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                PermissionRow(
                    icon: "calendar",
                    title: "Calendar",
                    description: "View your upcoming events",
                    isGranted: calendarManager.isAuthorized,
                    onRequest: {
                        calendarManager.requestAuthorization()
                    }
                )
                
                PermissionRow(
                    icon: "bell",
                    title: "Notifications",
                    description: "Get notified about important events",
                    isGranted: true,
                    onRequest: {}
                )
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let onRequest: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button("Allow") {
                    onRequest()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Completion View

struct CompletionView: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .symbolEffect(.bounce, value: true)
            
            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Enjoy your enhanced Mac experience")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Button("Get Started") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
