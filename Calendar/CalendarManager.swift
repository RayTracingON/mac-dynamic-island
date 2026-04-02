import Foundation
import EventKit
import Combine
import AppKit

/// Manager for calendar and event access using EventKit
class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    @Published var isAuthorized: Bool = false
    @Published var events: [EKEvent] = []
    @Published var upcomingEvents: [EKEvent] = []
    @Published var todayEvents: [EKEvent] = []
    @Published var error: String?
    
    private let eventStore = EKEventStore()
    private var refreshTimer: Timer?
    
    private init() {
        checkAuthorization()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Authorization
    
    func checkAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .fullAccess, .authorized:
            isAuthorized = true
        case .writeOnly:
            isAuthorized = true
        case .notDetermined:
            requestAuthorization()
        case .denied, .restricted:
            isAuthorized = false
            error = "Calendar access denied. Please enable in System Settings."
        @unknown default:
            isAuthorized = false
        }
    }
    
    func requestAuthorization() {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    
                    if let error = error {
                        self?.error = error.localizedDescription
                    } else if granted {
                        self?.start()
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    
                    if let error = error {
                        self?.error = error.localizedDescription
                    } else if granted {
                        self?.start()
                    }
                }
            }
        }
    }
    
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Lifecycle
    
    func start() {
        guard isAuthorized else {
            checkAuthorization()
            return
        }
        
        // Load initial events
        loadEvents()
        
        // Set up refresh timer
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.loadEvents()
        }
        
        // Listen for calendar changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCalendarChanged),
            name: .EKEventStoreChanged,
            object: eventStore
        )
    }
    
    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleCalendarChanged() {
        loadEvents()
    }
    
    // MARK: - Event Loading
    
    func loadEvents() {
        guard isAuthorized else { return }
        
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        
        let predicate = eventStore.predicateForEvents(
            withStart: now,
            end: endDate,
            calendars: nil
        )
        
        let fetchedEvents = eventStore.events(matching: predicate)
        
        DispatchQueue.main.async { [weak self] in
            self?.events = fetchedEvents
            self?.updateUpcomingEvents()
            self?.updateTodayEvents()
        }
    }
    
    private func updateUpcomingEvents() {
        let now = Date()
        let hours = SettingsDefaults.shared.get(SettingsDefaults.upcomingEventLookAheadDuration)
        let endLookScope = Calendar.current.date(byAdding: .hour, value: hours, to: now) ?? Date.distantFuture
        
        upcomingEvents = events
            .filter { event in
                return event.startDate >= now && event.startDate <= endLookScope
            }
            .sorted { $0.startDate < $1.startDate }
            .prefix(5)
            .map { $0 }
    }
    
    private func updateTodayEvents() {
        let calendar = Calendar.current
        let now = Date()
        
        todayEvents = events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: now)
        }
        .sorted { $0.startDate < $1.startDate }
    }
    
    // MARK: - Event Queries
    
    func getEvents(for date: Date) -> [EKEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )
        
        return eventStore.events(matching: predicate)
    }
    
    func getEventsInRange(start: Date, end: Date) -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )
        
        return eventStore.events(matching: predicate)
    }
    
    // MARK: - Event Creation
    
    func createEvent(title: String, startDate: Date, endDate: Date, notes: String? = nil, location: String? = nil) throws {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.location = location
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        try eventStore.save(event, span: .thisEvent)
        
        loadEvents()
    }
    
    // MARK: - Event Modification
    
    func updateEvent(_ event: EKEvent) throws {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }
        
        try eventStore.save(event, span: .thisEvent)
        loadEvents()
    }
    
    func deleteEvent(_ event: EKEvent) throws {
        guard isAuthorized else {
            throw CalendarError.notAuthorized
        }
        
        try eventStore.remove(event, span: .thisEvent)
        loadEvents()
    }
    
    // MARK: - Computed Properties
    
    var nextEvent: EKEvent? {
        return upcomingEvents.first
    }
    
    var hasEventsToday: Bool {
        return !todayEvents.isEmpty
    }
    
    var upcomingEventCount: Int {
        return upcomingEvents.count
    }
    
    // MARK: - Formatting
    
    func formatEventTime(_ event: EKEvent) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if event.isAllDay {
            return "All Day"
        } else {
            return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
        }
    }
    
    func formatEventDate(_ event: EKEvent) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return formatter.string(from: event.startDate)
    }
}

// MARK: - Errors

enum CalendarError: Error {
    case notAuthorized
    case eventNotFound
    case saveFailed
}
