import Foundation
import EventKit
import Combine

/// Manager for calendar event operations
class EventManager: ObservableObject {
    static let shared = EventManager()
    
    private let calendarManager = CalendarManager.shared
    
    private init() {}
    
    // MARK: - Event Creation
    
    func createQuickEvent(title: String, in minutes: Int) throws {
        let startDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        let endDate = startDate.addingTimeInterval(3600) // 1 hour duration
        
        try calendarManager.createEvent(
            title: title,
            startDate: startDate,
            endDate: endDate
        )
    }
    
    func createAllDayEvent(title: String, on date: Date) throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        try calendarManager.createEvent(
            title: title,
            startDate: startOfDay,
            endDate: endOfDay
        )
    }
    
    // MARK: - Event Queries
    
    func eventsThisWeek() -> [EKEvent] {
        let now = Date()
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        return calendarManager.getEventsInRange(start: now, end: endOfWeek)
    }
    
    func eventsToday() -> [EKEvent] {
        return calendarManager.todayEvents
    }
    
    func eventsTomorrow() -> [EKEvent] {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        return calendarManager.getEvents(for: tomorrow)
    }
    
    func nextEvent() -> EKEvent? {
        return calendarManager.nextEvent
    }
    
    // MARK: - Event Checks
    
    func hasEventsToday() -> Bool {
        return !calendarManager.todayEvents.isEmpty
    }
    
    func hasUpcomingEvents() -> Bool {
        return !calendarManager.upcomingEvents.isEmpty
    }
    
    func isEventSoon(_ event: EKEvent, within minutes: Int = 15) -> Bool {
        let now = Date()
        let threshold = now.addingTimeInterval(TimeInterval(minutes * 60))
        return event.startDate > now && event.startDate <= threshold
    }
    
    // MARK: - Event Formatting
    
    func formatEventTime(_ event: EKEvent) -> String {
        return calendarManager.formatEventTime(event)
    }
    
    func formatEventDate(_ event: EKEvent) -> String {
        return calendarManager.formatEventDate(event)
    }
    
    func relativeTimeString(for event: EKEvent) -> String {
        let now = Date()
        let timeInterval = event.startDate.timeIntervalSince(now)
        
        if timeInterval < 0 {
            return "Started"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "In \(minutes) min"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "In \(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            let days = Int(timeInterval / 86400)
            return "In \(days) day\(days > 1 ? "s" : "")"
        }
    }
    
    // MARK: - Event Summary
    
    func todaySummary() -> String {
        let events = eventsToday()
        
        if events.isEmpty {
            return "No events today"
        } else if events.count == 1 {
            return "1 event today"
        } else {
            return "\(events.count) events today"
        }
    }
    
    func upcomingSummary() -> String {
        let upcoming = calendarManager.upcomingEvents
        
        if upcoming.isEmpty {
            return "No upcoming events"
        } else if let next = upcoming.first {
            return "Next: \(next.title ?? "Event") \(relativeTimeString(for: next))"
        }
        
        return ""
    }
}
