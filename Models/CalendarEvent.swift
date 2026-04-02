import Combine
import Foundation
import EventKit

/// Wrapper for EKEvent with additional functionality
struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String?
    let notes: String?
    let calendar: EKCalendar
    let color: String
    
    init(from ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier
        self.title = ekEvent.title
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.isAllDay = ekEvent.isAllDay
        self.location = ekEvent.location
        self.notes = ekEvent.notes
        self.calendar = ekEvent.calendar
        self.color = ekEvent.calendar.cgColor.components?.description ?? "blue"
    }
    
    var duration: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
    
    var isUpcoming: Bool {
        return startDate > Date()
    }
    
    var isInProgress: Bool {
        let now = Date()
        return startDate <= now && endDate >= now
    }
    
    var isPast: Bool {
        return endDate < Date()
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if isAllDay {
            return "All Day"
        } else {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: startDate)
    }
}
