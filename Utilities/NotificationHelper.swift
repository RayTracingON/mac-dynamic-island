import UserNotifications
import AppKit
import os

/// User notification helper
class NotificationHelper: NSObject {
    static let shared = NotificationHelper()
    
    private let center = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        center.delegate = self
    }
    
    // MARK: - Authorization
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "NotificationHelper")
                logger.error("Notification authorization error: \(error.localizedDescription, privacy: .public)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    // MARK: - Send Notifications
    
    func sendNotification(
        title: String,
        subtitle: String? = nil,
        body: String,
        identifier: String = UUID().uuidString,
        categoryIdentifier: String? = nil,
        userInfo: [AnyHashable: Any]? = nil,
        delay: TimeInterval = 0
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        content.body = body
        content.sound = .default
        
        if let categoryIdentifier = categoryIdentifier {
            content.categoryIdentifier = categoryIdentifier
        }
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        let trigger = delay > 0 ? UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false) : nil
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "NotificationHelper")
                logger.error("Failed to send notification: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    func sendBatteryNotification(level: Int, isCharging: Bool) {
        let title = isCharging ? "Battery Charging" : "Low Battery"
        let body = "Battery level: \(level)%"
        
        sendNotification(
            title: title,
            body: body,
            identifier: "battery-\(level)",
            categoryIdentifier: "battery"
        )
    }
    
    func sendMusicNotification(title: String, artist: String, albumArt: NSImage? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "Now Playing"
        content.subtitle = artist
        content.body = title
        content.sound = nil
        content.categoryIdentifier = "music"
        
        // Add album art as attachment if available
        if let albumArt = albumArt,
           let data = albumArt.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: data),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("png")
            
            do {
                try pngData.write(to: tempURL)
                let attachment = try UNNotificationAttachment(identifier: "albumArt", url: tempURL)
                content.attachments = [attachment]
            } catch {
                let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "NotificationHelper")
                logger.error("Failed to attach album art: \(error.localizedDescription, privacy: .public)")
            }
        }
        
        let request = UNNotificationRequest(identifier: "music-now-playing", content: content, trigger: nil)
        
        center.add(request) { error in
            if let error = error {
                let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "NotificationHelper")
                logger.error("Failed to send music notification: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    func sendCalendarNotification(eventTitle: String, time: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        sendNotification(
            title: "Upcoming Event",
            subtitle: formatter.string(from: time),
            body: eventTitle,
            identifier: "calendar-\(time.timeIntervalSince1970)",
            categoryIdentifier: "calendar"
        )
    }
    
    // MARK: - Management
    
    func removePendingNotification(withIdentifier identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func removeDeliveredNotification(withIdentifier identifier: String) {
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    func removeAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    func removeAllDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
    }
    
    // MARK: - Categories
    
    func registerNotificationCategories() {
        let batteryCategory = UNNotificationCategory(
            identifier: "battery",
            actions: [],
            intentIdentifiers: []
        )
        
        let musicCategory = UNNotificationCategory(
            identifier: "music",
            actions: [],
            intentIdentifiers: []
        )
        
        let calendarCategory = UNNotificationCategory(
            identifier: "calendar",
            actions: [],
            intentIdentifiers: []
        )
        
        center.setNotificationCategories([batteryCategory, musicCategory, calendarCategory])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationHelper: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap
        handleNotificationTap(identifier: identifier, userInfo: userInfo)
        
        completionHandler()
    }
    
    private func handleNotificationTap(identifier: String, userInfo: [AnyHashable: Any]) {
        let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "NotificationHelper")
        logger.debug("Notification tapped: \(identifier, privacy: .public)")
        
        // Post notification for app to handle
        NotificationCenter.default.post(
            name: .userNotificationTapped,
            object: nil,
            userInfo: ["identifier": identifier, "data": userInfo]
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userNotificationTapped = Notification.Name("userNotificationTapped")
}
