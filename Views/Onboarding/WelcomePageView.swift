import SwiftUI

/// Welcome page in onboarding
struct WelcomePageView: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App icon
            VStack(spacing: 20) {
                if let iconImage = NSImage(named: "AppIcon") {
                    Image(nsImage: iconImage)
                        .resizable()
                        .frame(width: 120, height: 120)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.accentColor)
                }
                
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Mac灵动岛")
                    .font(.system(size: 48, weight: .bold))
            }
            
            // Description
            VStack(spacing: 16) {
                Text("Transform your Mac's notch into a dynamic, interactive hub")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text("Display music, battery status, calendar events, and more—all in one beautiful interface")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // Features highlight
            HStack(spacing: 40) {
                FeatureBadge(icon: "music.note", title: "Music")
                FeatureBadge(icon: "battery.100", title: "Battery")
                FeatureBadge(icon: "calendar", title: "Calendar")
                FeatureBadge(icon: "folder", title: "Files")
            }
            
            Spacer()
        }
        .padding(60)
    }
}

struct FeatureBadge: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.accentColor)
                .frame(width: 60, height: 60)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(12)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    WelcomePageView()
        .frame(width: 800, height: 600)
}
