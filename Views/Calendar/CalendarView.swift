import SwiftUI
import EventKit
import AppKit

/// Calendar view showing upcoming events
struct CalendarView: View {
    @ObservedObject var calendarManager = CalendarManager.shared
    @ObservedObject var eventManager = EventManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Events list
            if !calendarManager.isAuthorized {
                unauthorizedView
            } else if calendarManager.upcomingEvents.isEmpty {
                emptyView
            } else {
                eventsList
            }
        }
        .background(Material.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Image(systemName: "calendar")
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
            
            Text("Calendar")
                .font(.headline)
            
            Spacer()
            
            if calendarManager.hasEventsToday {
                Text(eventManager.todaySummary())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Content Views
    
    private var eventsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(calendarManager.upcomingEvents, id: \.eventIdentifier) { event in
                    EventRowView(event: event)
                }
            }
            .padding(12)
        }
        .frame(maxHeight: 300)
    }
    
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No Upcoming Events")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var unauthorizedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text(calendarManager.error != nil ? "Access Denied" : "Access Required")
                .font(.headline)
            
            if let error = calendarManager.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Open System Settings") {
                    calendarManager.openSystemSettings()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("We need access to show your upcoming events.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    
                Button("Grant Access") {
                    calendarManager.requestAuthorization()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Event Row

struct EventRowView: View {
    let event: EKEvent
    @ObservedObject var eventManager = EventManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(cgColor: event.calendar.cgColor))
                .frame(width: 4, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(event.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // Time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(eventManager.formatEventTime(event))
                            .font(.caption)
                    }
                    
                    // Location
                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.system(size: 10))
                            Text(location)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Join Button
            if SettingsDefaults.shared.get(SettingsDefaults.showMeetingJoinButton), let url = getMeetingURL(for: event) {
                Button(action: {
                    NSWorkspace.shared.open(url)
                }) {
                    Text("Join")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            
            // Relative time
            Text(eventManager.relativeTimeString(for: event))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func getMeetingURL(for event: EKEvent) -> URL? {
        // 1. Check event structure for strict URL
        if let url = event.url {
            return url
        }
        
        // 2. Scan notes and location for meeting links
        let pattern = "https?:\\/\\/(?:[a-zA-Z0-9-]+\\.)?(?:zoom\\.us|teams\\.microsoft\\.com|meet\\.google\\.com|webex\\.com)\\/[^\\s]+"
        
        // Check notes
        if let notes = event.notes, let url = findURL(in: notes, pattern: pattern) {
            return url
        }
        
        // Check location
        if let location = event.location, let url = findURL(in: location, pattern: pattern) {
            return url
        }
        
        return nil
    }
    
    private func findURL(in text: String, pattern: String) -> URL? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            if let swiftRange = Range(match.range, in: text) {
                return URL(string: String(text[swiftRange]))
            }
        }
        return nil
    }
}

#Preview {
    CalendarView()
        .frame(width: 400, height: 400)
}
