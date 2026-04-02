import Foundation
import SwiftUI
import Combine

/// Main app coordinator for managing navigation and state
@MainActor
final class AppCoordinator: ObservableObject {
    static let shared = AppCoordinator()
    
    // MARK: - Published State
    
    @Published var showSettings = false
    @Published var showOnboarding = false
    @Published var showShelf = false
    @Published var showCalendar = false
    @Published var showMusicPlayer = false
    
    // MARK: - Managers
    
    let appState = AppState()
    let musicManager = MusicPlayerManager.shared
    let batteryManager = BatteryActivityManager.shared
    let calendarManager = CalendarManager.shared
    let notificationManager = NotificationManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
        checkFirstLaunch()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Monitor music state
        musicManager.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                if isPlaying {
                    self?.showMusicPlayer = true
                }
            }
            .store(in: &cancellables)
        
        // Monitor battery state
        batteryManager.$isCharging
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isCharging in
                if isCharging {
                    self?.showBatteryNotification()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkFirstLaunch() {
        let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if !hasLaunched {
            showOnboarding = true
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
    
    // MARK: - Navigation
    
    func openSettings() {
        showSettings = true
    }
    
    func closeSettings() {
        showSettings = false
    }
    
    func openShelf() {
        showShelf = true
    }
    
    func closeShelf() {
        showShelf = false
    }
    
    func openCalendar() {
        showCalendar = true
    }
    
    func closeCalendar() {
        showCalendar = false
    }
    
    func openMusicPlayer() {
        showMusicPlayer = true
    }
    
    func closeMusicPlayer() {
        showMusicPlayer = false
    }
    
    func completeOnboarding() {
        showOnboarding = false
    }
    
    // MARK: - Actions
    
    func handleDroppedFiles(_ urls: [URL]) {
        guard let firstURL = urls.first else { return }
        appState.updateFile(url: firstURL)
        openShelf()
        
        // Add to shelf
        ShelfStateViewModel.shared.addItems(urls: urls)
    }
    
    func handleClipboardUpdate(_ text: String) {
        appState.updateClipboard(text: text)
    }
    
    func toggleMusic() {
        if musicManager.isPlaying {
            musicManager.pause()
        } else {
            musicManager.play()
        }
    }
    
    // MARK: - Notifications
    
    private func showBatteryNotification() {
        notificationManager.sendNotification(
            title: "Battery Status",
            body: "Battery is now charging",
            identifier: "battery-charging"
        )
    }
    
    func showEventNotification(_ event: String) {
        notificationManager.sendNotification(
            title: "Calendar Event",
            body: event,
            identifier: "calendar-event"
        )
    }
}
