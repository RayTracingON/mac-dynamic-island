import Foundation
import Combine
import AppKit
import AVFoundation
import os.log

final class TimerManager: ObservableObject {
    static var shared: TimerManager!
    
    static func configure(appState: AppState) {
        shared = TimerManager(appState: appState)
    }
    
    @Published var isRunning = false
    @Published var remaining: TimeInterval = 0
    @Published var total: TimeInterval = 0
    
    private weak var appState: AppState?
    private var countdownTask: Task<Void, Never>?
    private var currentActivityId: UUID?
    private var startTime: Date?
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func startTimer(duration: TimeInterval) {
        // Stop any existing timer
        stop()
        
        total = duration
        remaining = duration
        isRunning = true
        startTime = Date()
        
        // TRIGGER VISIBILITY - ✅ MainActor 隔离修复
        Task { @MainActor in
            appState?.showOverlay(reason: .timer)
        }
        
        // Create initial activity
        let activity = Activity.timer(remaining: remaining, progress: 0)
        currentActivityId = activity.id
        Task { @MainActor in
            ActivityCenter.shared.post(activity)
        }
        Log.timerStarted(duration)
        
        // Start countdown task
        countdownTask = Task {
            while !Task.isCancelled && remaining > 0 {
                do {
                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms for smooth updates
                } catch {
                    break
                }
                
                // Update remaining time
                if let startTime = startTime {
                    remaining = max(0, total - Date().timeIntervalSince(startTime))
                } else {
                    remaining = max(0, remaining - 0.1)
                }
                
                // Update activity on main thread
                await MainActor.run {
                    if remaining > 0, let activityId = currentActivityId {
                        ActivityCenter.shared.updateTimer(id: activityId, remaining: remaining, total: total)
                    }
                }
                
                // Check if timer is done
                if remaining <= 0 {
                    Task { @MainActor in
                        await self.finishTimer()
                    }
                    break
                }
            }
        }
    }
    
    func stop() {
        countdownTask?.cancel()
        countdownTask = nil
        isRunning = false
        remaining = 0
        total = 0
        startTime = nil
        
        if let activityId = currentActivityId {
            Task { @MainActor in
                ActivityCenter.shared.dismiss(activityId)
            }
        }
        currentActivityId = nil
        Log.timerStopped()
    }
    
    @MainActor
    private func finishTimer() {
        isRunning = false
        remaining = 0
        countdownTask = nil
        
        // Dismiss old timer activity
        if let activityId = currentActivityId {
            ActivityCenter.shared.dismiss(activityId)
        }
        
        // TRIGGER VISIBILITY for completion
        appState?.showOverlay(reason: .timer)
        
        // Post completion activity
        let doneActivity = Activity.timerDone()
        currentActivityId = doneActivity.id
        Task {
            ActivityCenter.shared.post(doneActivity)
        }
        
        // Play system sound
        playCompletionSound()
        
        Log.timerStopped()
    }
    
    private func playCompletionSound() {
        // Use system beep sound (builtin only)
        NSSound.beep()
    }
    
    deinit {
        stop()
    }
}
