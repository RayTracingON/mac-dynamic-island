import Foundation

// MARK: - Activity Types

enum ActivityKind: String, Codable {
    case clipboard
    case drop
    case timer
    case info
}

struct ActivityAction: Identifiable, Codable {
    let id: UUID
    let title: String
    let action: String // "dismiss", "reveal", "copy", "open-tray", etc.

    init(title: String, action: String) {
        self.id = UUID()
        self.title = title
        self.action = action
    }
}

// MARK: - Activity

struct Activity: Identifiable, Codable {
    let id: UUID
    let kind: ActivityKind
    let title: String
    var message: String                // ✅ runtime 可更新：计时器会改文案
    let iconName: String               // SF Symbol
    var progress: Double?              // ✅ runtime 可更新：计时器会改进度
    let isPersistent: Bool
    let createdAt: Date
    let expiresAt: Date?               // nil for persistent; set for transient
    let priority: Int                  // higher wins; default 50, timer=100, drop=80, clipboard=50
    var actions: [ActivityAction]      // ✅ 你原来就是 var，保留

    init(
        id: UUID = UUID(),
        kind: ActivityKind,
        title: String,
        message: String,
        iconName: String,
        progress: Double? = nil,
        isPersistent: Bool = false,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        priority: Int = 50,
        actions: [ActivityAction] = []
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.message = message
        self.iconName = iconName
        self.progress = progress
        self.isPersistent = isPersistent
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.priority = priority
        self.actions = actions
    }

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() >= expiresAt
    }

    // MARK: - Factory Methods

    static func clipboard(message: String) -> Activity {
        Activity(
            kind: .clipboard,
            title: L("activity.clipboard.title"),
            message: message,
            iconName: "document.on.clipboard.fill",
            progress: nil,
            isPersistent: false,
            expiresAt: Date().addingTimeInterval(3),
            priority: 50,
            actions: [
                ActivityAction(title: L("button.dismiss"), action: "dismiss")
            ]
        )
    }

    static func drop(itemCount: Int) -> Activity {
        Activity(
            kind: .drop,
            title: L("activity.drop.title"),
            message: L("activity.drop.message", "\(itemCount)"),
            iconName: "arrow.down.doc",
            progress: nil,
            isPersistent: false,
            expiresAt: Date().addingTimeInterval(4),
            priority: 80,
            actions: [
                ActivityAction(title: L("activity.drop.open_tray"), action: "open-tray"),
                ActivityAction(title: L("button.dismiss"), action: "dismiss")
            ]
        )
    }

    static func timer(remaining: TimeInterval, progress: Double) -> Activity {
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        let timeStr = String(format: "%d:%02d", minutes, seconds)

        return Activity(
            kind: .timer,
            title: L("activity.timer.title"),
            message: timeStr,
            iconName: "timer",
            progress: progress,
            isPersistent: true,
            expiresAt: nil,
            priority: 100,
            actions: [
                ActivityAction(title: L("activity.timer.stop"), action: "stop-timer"),
                ActivityAction(title: L("button.dismiss"), action: "dismiss")
            ]
        )
    }

    static func timerDone() -> Activity {
        Activity(
            kind: .info,
            title: L("activity.timer.done.title"),
            message: L("activity.timer.done.message"),
            iconName: "checkmark.circle.fill",
            progress: nil,
            isPersistent: false,
            expiresAt: Date().addingTimeInterval(3),
            priority: 100,
            actions: [
                ActivityAction(title: L("button.dismiss"), action: "dismiss")
            ]
        )
    }

    static func info(
        title: String,
        message: String,
        icon: String = "info.circle.fill",
        duration: TimeInterval = 3
    ) -> Activity {
        Activity(
            kind: .info,
            title: title,
            message: message,
            iconName: icon,
            progress: nil,
            isPersistent: false,
            expiresAt: Date().addingTimeInterval(duration),
            priority: 50,
            actions: [
                ActivityAction(title: L("button.dismiss"), action: "dismiss")
            ]
        )
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, kind, title, message, iconName, progress, isPersistent
        case createdAt, expiresAt, priority, actions
    }
}

