import Foundation
import Combine

// MARK: - Performance Constants

/// Performance tuning constants
enum PerformanceConfig {
    /// Clipboard polling interval (seconds)
    /// 0.6s is a good balance between responsiveness and CPU usage
    static let clipboardPollInterval: TimeInterval = 0.6
    
    /// Minimum interval between UI updates (seconds)
    /// Prevents excessive redraws
    static let minUIUpdateInterval: TimeInterval = 0.016  // ~60fps max
    
    /// Debounce delay for expensive operations
    static let debounceDelay: TimeInterval = 0.1
    
    /// Auto-hide delay for transient content
    static let autoHideDelay: TimeInterval = 1.5
    
    /// Animation duration for layout changes
    static let layoutAnimationDuration: TimeInterval = 0.35
    
    /// Maximum items to render in a list before virtualizing
    static let maxRenderedItems: Int = 50
}

// MARK: - Debouncer

/// Debounces rapid calls to prevent CPU spikes
/// Use for expensive operations triggered by user input
final class Debouncer {
    private var workItem: DispatchWorkItem?
    private let delay: TimeInterval
    private let queue: DispatchQueue
    
    init(delay: TimeInterval = PerformanceConfig.debounceDelay, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    func debounce(_ action: @escaping () -> Void) {
        workItem?.cancel()
        let item = DispatchWorkItem(block: action)
        workItem = item
        queue.asyncAfter(deadline: .now() + delay, execute: item)
    }
    
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}

// MARK: - Throttler

/// Throttles calls to a maximum rate
/// Use for continuous updates (e.g., drag, scroll)
final class Throttler {
    private var lastExecutionTime: Date?
    private let interval: TimeInterval
    private let queue: DispatchQueue
    
    init(interval: TimeInterval = PerformanceConfig.minUIUpdateInterval, queue: DispatchQueue = .main) {
        self.interval = interval
        self.queue = queue
    }
    
    func throttle(_ action: @escaping () -> Void) {
        let now = Date()
        
        if let lastTime = lastExecutionTime,
           now.timeIntervalSince(lastTime) < interval {
            return  // Skip this call
        }
        
        lastExecutionTime = now
        queue.async(execute: action)
    }
    
    func reset() {
        lastExecutionTime = nil
    }
}

// MARK: - Lazy Loader

/// Lazy initialization wrapper for expensive resources
/// Defers creation until first access
@propertyWrapper
struct LazyResource<T> {
    private var storage: T?
    private let factory: () -> T
    
    init(wrappedValue: @autoclosure @escaping () -> T) {
        self.factory = wrappedValue
    }
    
    var wrappedValue: T {
        mutating get {
            if storage == nil {
                storage = factory()
            }
            return storage!
        }
    }
    
    var projectedValue: Bool {
        storage != nil
    }
    
    mutating func reset() {
        storage = nil
    }
}

// MARK: - Idle Detector

/// Detects when the app is idle to reduce background work
/// Idle = no user interaction for a period
final class IdleDetector: ObservableObject {
    static let shared = IdleDetector()
    
    @Published private(set) var isIdle: Bool = false
    
    private var lastActivityTime: Date = Date()
    private var idleTimer: Timer?
    private let idleThreshold: TimeInterval = 30  // 30 seconds without interaction
    
    private init() {
        startIdleTimer()
    }
    
    /// Call this when user interacts with the app
    func recordActivity() {
        lastActivityTime = Date()
        if isIdle {
            isIdle = false
        }
    }
    
    private func startIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.checkIdleState()
        }
    }
    
    private func checkIdleState() {
        let timeSinceActivity = Date().timeIntervalSince(lastActivityTime)
        let shouldBeIdle = timeSinceActivity >= idleThreshold
        
        if shouldBeIdle != isIdle {
            isIdle = shouldBeIdle
            #if DEBUG
            print("🔋 IdleDetector: \(isIdle ? "Entering idle mode" : "Exiting idle mode")")
            #endif
        }
    }
    
    deinit {
        idleTimer?.invalidate()
    }
}

// MARK: - Memory Pressure Monitor

/// Monitors system memory pressure
/// Use to adapt caching behavior
final class MemoryPressureMonitor {
    static let shared = MemoryPressureMonitor()
    
    enum PressureLevel {
        case normal
        case warning
        case critical
    }
    
    private(set) var currentPressure: PressureLevel = .normal
    private var source: DispatchSourceMemoryPressure?
    
    var onPressureChange: ((PressureLevel) -> Void)?
    
    private init() {
        setupMonitor()
    }
    
    private func setupMonitor() {
        source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .main)
        
        source?.setEventHandler { [weak self] in
            guard let self = self, let source = self.source else { return }
            
            let event = source.data
            let newPressure: PressureLevel
            
            if event.contains(.critical) {
                newPressure = .critical
            } else if event.contains(.warning) {
                newPressure = .warning
            } else {
                newPressure = .normal
            }
            
            if newPressure != self.currentPressure {
                self.currentPressure = newPressure
                self.onPressureChange?(newPressure)
                #if DEBUG
                print("🧠 MemoryPressure: \(newPressure)")
                #endif
            }
        }
        
        source?.resume()
    }
    
    deinit {
        source?.cancel()
    }
}

// MARK: - Combine Extensions for Performance

extension Publisher {
    /// Debounces the publisher output
    func debounced(for interval: TimeInterval = PerformanceConfig.debounceDelay) -> AnyPublisher<Output, Failure> {
        self.debounce(for: .seconds(interval), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Throttles the publisher output
    func throttled(for interval: TimeInterval = PerformanceConfig.minUIUpdateInterval) -> AnyPublisher<Output, Failure> {
        self.throttle(for: .seconds(interval), scheduler: DispatchQueue.main, latest: true)
            .eraseToAnyPublisher()
    }
}

// MARK: - SwiftUI Performance Helpers

import SwiftUI

extension View {
    /// Applies performance-optimized animation
    /// Uses reduced motion setting from AppSettings
    func performantAnimation<V: Equatable>(_ value: V) -> some View {
        self.animation(
            AppSettings.shared.shouldUseReducedMotion()
                ? .none
                : .spring(response: PerformanceConfig.layoutAnimationDuration, dampingFraction: 0.85),
            value: value
        )
    }
    
    /// Conditionally renders based on idle state
    /// Use for non-essential decorative elements
    @ViewBuilder
    func renderWhenActive() -> some View {
        if !IdleDetector.shared.isIdle {
            self
        }
    }
}
