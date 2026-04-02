import SwiftUI

/// Permissions page in onboarding
struct PermissionsPageView: View {
    @State private var accessibilityGranted = false
    @State private var notificationsGranted = false
    @State private var calendarGranted = false
    
    var allPermissionsGranted: Bool {
        accessibilityGranted && notificationsGranted && calendarGranted
    }
    
    var body: some View {
        VStack(spacing: 40) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Grant Permissions")
                    .font(.system(size: 36, weight: .bold))
                
                Text("Mac灵动岛 needs a few permissions to work properly")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Permission items
            VStack(spacing: 20) {
                PermissionItem(
                    icon: "hand.raised.fill",
                    title: "Accessibility",
                    description: "Required to show the notch overlay and respond to hotkeys",
                    isGranted: $accessibilityGranted,
                    action: requestAccessibility
                )
                
                PermissionItem(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Show alerts for battery status and calendar events",
                    isGranted: $notificationsGranted,
                    action: requestNotifications
                )
                
                PermissionItem(
                    icon: "calendar",
                    title: "Calendar",
                    description: "Display your upcoming events in the notch",
                    isGranted: $calendarGranted,
                    action: requestCalendar
                )
            }
            
            if allPermissionsGranted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("All permissions granted!")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
            }
        }
        .padding(60)
        .onAppear {
            checkPermissions()
        }
    }
    
    // MARK: - Permission Requests
    
    private func checkPermissions() {
        accessibilityGranted = AXIsProcessTrusted()
        notificationsGranted = NotificationManager.shared.isAuthorized
        calendarGranted = CalendarManager.shared.isAuthorized
    }
    
    private func requestAccessibility() {
        SystemPreferencesManager.shared.openAccessibilityPreferences()
        
        // Check again after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            checkPermissions()
        }
    }
    
    private func requestNotifications() {
        NotificationManager.shared.requestAuthorization { granted in
            notificationsGranted = granted
        }
    }
    
    private func requestCalendar() {
        CalendarManager.shared.requestAuthorization()
        
        // Check again after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            checkPermissions()
        }
    }
}

struct PermissionItem: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.accentColor)
                .frame(width: 60, height: 60)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(12)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Status/Action
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            } else {
                Button("Grant") {
                    action()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    PermissionsPageView()
        .frame(width: 800, height: 600)
}
