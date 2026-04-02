import Foundation
import Combine
import OSLog

@MainActor
final class ActivityCenter: ObservableObject {
    static let shared = ActivityCenter()
    
    @Published var activities: [Activity] = []
    var topActivity: Activity? {
        activities.sorted { $0.priority > $1.priority }.first
    }
    
    private var timers: [UUID: Timer] = [:]
    private var updateTask: Task<Void, Never>?
    private let queue = DispatchQueue(label: "com.lingdonggao.activity-center")
    private let logger = os.Logger(subsystem: "com.maclingdonggao.overlay", category: "activity")
    
    init() {
        // Start expiry check loop (every 200ms)
        startExpiryLoop()
    }
    
    // MARK: - Public API
    
    func post(_ activity: Activity) {
        activities.append(activity)
        #if DEBUG
        logger.debug("🔴 ActivityCenter.post(): \(String(describing: activity.kind)) | title=\(activity.title) | total=\(self.activities.count)")
        #endif
        Log.activityPosted(activity.title, String(describing: activity.kind))
        
        // Schedule expiry if transient
        if !activity.isPersistent, let expiresAt = activity.expiresAt {
            let delay = max(0.1, expiresAt.timeIntervalSinceNow)
            let timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.dismiss(activity.id)
                }
            }
            timers[activity.id] = timer
        }
    }
    
    func dismiss(_ id: UUID) {
        if let activity = activities.first(where: { $0.id == id }) {
            Log.activityDismissed(activity.title, String(describing: activity.kind))
        }
        activities.removeAll { $0.id == id }
        if let timer = timers[id] {
            timer.invalidate()
            timers[id] = nil
        }
    }
    
    func dismissAll() {
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
        activities.removeAll()
    }
    
    // MARK: - Activity Management
    
    func updateTimer(id: UUID, remaining: TimeInterval, total: TimeInterval) {
        if let index = activities.firstIndex(where: { $0.id == id }) {
            let progress = max(0, min(1, (total - remaining) / total))
            var updated = activities[index]
            updated.progress = progress
            updated.message = String(format: "%d:%02d", Int(remaining) / 60, Int(remaining) % 60)
            activities[index] = updated
        }
    }
    
    // MARK: - Expiry Loop
    
    private func startExpiryLoop() {
        updateTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
                checkExpiredActivities()
            }
        }
    }
    
    @MainActor
    private func checkExpiredActivities() {
        let expired = activities.filter { !$0.isPersistent && $0.isExpired }
        for activity in expired {
            dismiss(activity.id)
        }
    }
    
    deinit {
        updateTask?.cancel()
        timers.values.forEach { $0.invalidate() }
    }
}
