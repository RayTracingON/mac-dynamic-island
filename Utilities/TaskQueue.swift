import Foundation

/// Background task queue manager
class TaskQueue {
    static let shared = TaskQueue()
    
    private let queue = DispatchQueue(label: "com.mac灵动岛.taskqueue", qos: .utility, attributes: .concurrent)
    private let serialQueue = DispatchQueue(label: "com.mac灵动岛.serial")
    
    private var activeTasks: [String: Task<Void, Never>] = [:]
    private let lock = NSLock()
    
    private init() {}
    
    // MARK: - Async Tasks
    
    @discardableResult
    func enqueue<T>(
        id: String? = nil,
        priority: TaskPriority = .medium,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        let taskId = id ?? UUID().uuidString
        
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask(priority: priority) {
                try await operation()
            }
            
            let result = try await group.next()!
            removeTask(taskId)
            return result
        }
    }
    
    func enqueueWithCompletion<T>(
        id: String? = nil,
        operation: @escaping () async throws -> T,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let taskId = id ?? UUID().uuidString
        
        let task = Task {
            do {
                let result = try await operation()
                await MainActor.run {
                    completion(.success(result))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
            removeTask(taskId)
        }
        
        addTask(taskId, task: task)
    }
    
    // MARK: - Sync Tasks
    
    func enqueueSync<T>(_ operation: @escaping () -> T) -> T {
        return queue.sync(execute: operation)
    }
    
    func enqueueAsync(_ operation: @escaping () -> Void) {
        queue.async(execute: operation)
    }
    
    func enqueueSerial(_ operation: @escaping () -> Void) {
        serialQueue.async(execute: operation)
    }
    
    // MARK: - Delayed Tasks
    
    func enqueueDelayed(
        delay: TimeInterval,
        operation: @escaping () -> Void
    ) {
        queue.asyncAfter(deadline: .now() + delay, execute: operation)
    }
    
    // MARK: - Batch Operations
    
    func enqueueBatch<T>(
        operations: [() async throws -> T]
    ) async throws -> [T] {
        return try await withThrowingTaskGroup(of: T.self) { group in
            for operation in operations {
                group.addTask {
                    try await operation()
                }
            }
            
            var results: [T] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
    
    // MARK: - Task Management
    
    private func addTask(_ id: String, task: Task<Void, Never>) {
        lock.lock()
        defer { lock.unlock() }
        activeTasks[id] = task
    }
    
    private func removeTask(_ id: String) {
        lock.lock()
        defer { lock.unlock() }
        activeTasks.removeValue(forKey: id)
    }
    
    func cancelTask(_ id: String) {
        lock.lock()
        defer { lock.unlock() }
        activeTasks[id]?.cancel()
        activeTasks.removeValue(forKey: id)
    }
    
    func cancelAllTasks() {
        lock.lock()
        defer { lock.unlock() }
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
    }
    
    var activeTaskCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return activeTasks.count
    }
}
