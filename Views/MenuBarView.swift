import SwiftUI
import EventKit

/// Menu bar popover view
struct MenuBarView: View {
    @StateObject private var musicManager = MusicPlayerManager.shared
    @StateObject private var batteryManager = BatteryActivityManager.shared
    @StateObject private var calendarManager = CalendarManager.shared
    
    let onSettings: () -> Void
    let onQuit: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Mac灵动岛")
                    .font(.headline)
                
                Spacer()
                
                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Quick Info
            VStack(spacing: 12) {
                // Music
                if musicManager.isPlaying, let track = musicManager.currentTrack {
                    QuickInfoRow(
                        icon: "music.note",
                        title: track.title,
                        subtitle: track.artist,
                        color: .blue
                    )
                }
                
                // Battery
                QuickInfoRow(
                    icon: batteryManager.isCharging ? "bolt.fill" : "battery.100",
                    title: "Battery",
                    subtitle: "\(batteryManager.batteryLevel)%",
                    color: batteryManager.isCharging ? .green : .primary
                )
                
                // Calendar
                if let nextEvent = calendarManager.nextEvent {
                    QuickInfoRow(
                        icon: "calendar",
                        title: nextEvent.title,
                        subtitle: calendarManager.formatEventTime(nextEvent),
                        color: .orange
                    )
                }
            }
            .padding()
            
            Divider()
            
            // Actions
            VStack(spacing: 0) {
                MenuButton(title: "Open Shelf", icon: "folder") {
                    AppCoordinator.shared.openShelf()
                }
                
                MenuButton(title: "Open Calendar", icon: "calendar") {
                    AppCoordinator.shared.openCalendar()
                }
                
                Divider()
                
                MenuButton(title: "Settings", icon: "gearshape") {
                    onSettings()
                }
                
                MenuButton(title: "Quit", icon: "power", destructive: true) {
                    onQuit()
                }
            }
        }
        .frame(width: 280)
    }
}

struct QuickInfoRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    var destructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(destructive ? .red : .primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    MenuBarView(
        onSettings: {},
        onQuit: {}
    )
}
