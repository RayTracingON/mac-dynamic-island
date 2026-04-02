import Foundation

/// Debouncer for delaying actions
class AppDebouncer {
    private var workItem: DispatchWorkItem?
    private let delay: TimeInterval
    private let queue: DispatchQueue
    
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        
        let newWorkItem = DispatchWorkItem(block: action)
        workItem = newWorkItem
        
        queue.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
    
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}

/// Throttler for limiting action frequency
class AppThrottler {
    private var lastExecutionTime: Date?
    private let interval: TimeInterval
    private let queue: DispatchQueue
    
    init(interval: TimeInterval, queue: DispatchQueue = .main) {
        self.interval = interval
        self.queue = queue
    }
    
    func throttle(action: @escaping () -> Void) {
        let now = Date()
        
        if let lastTime = lastExecutionTime {
            let timeSinceLastExecution = now.timeIntervalSince(lastTime)
            
            if timeSinceLastExecution < interval {
                return
            }
        }
        
        lastExecutionTime = now
        queue.async(execute: action)
    }
    
    func reset() {
        lastExecutionTime = nil
    }
}
