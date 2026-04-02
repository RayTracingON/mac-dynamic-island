import Combine
import Foundation
import QuartzCore

/// Performance monitoring utility
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var measurements: [String: [TimeInterval]] = [:]
    private let queue = DispatchQueue(label: "com.mac灵动岛.performance")
    
    private init() {}
    
    // MARK: - Timing
    
    func measure<T>(_ label: String, block: () throws -> T) rethrows -> T {
        let start = CACurrentMediaTime()
        defer {
            let duration = CACurrentMediaTime() - start
            record(duration, for: label)
        }
        return try block()
    }
    
    func measureAsync<T>(_ label: String, block: () async throws -> T) async rethrows -> T {
        let start = CACurrentMediaTime()
        defer {
            let duration = CACurrentMediaTime() - start
            record(duration, for: label)
        }
        return try await block()
    }
    
    func startTiming(_ label: String) -> TimingToken {
        return TimingToken(label: label, startTime: CACurrentMediaTime())
    }
    
    func endTiming(_ token: TimingToken) {
        let duration = CACurrentMediaTime() - token.startTime
        record(duration, for: token.label)
    }
    
    // MARK: - Recording
    
    private func record(_ duration: TimeInterval, for label: String) {
        queue.async { [weak self] in
            self?.measurements[label, default: []].append(duration)
            
            // Keep only last 100 measurements
            if let count = self?.measurements[label]?.count, count > 100 {
                self?.measurements[label]?.removeFirst()
            }
        }
    }
    
    // MARK: - Statistics
    
    func statistics(for label: String) -> PerformanceStatistics? {
        return queue.sync { () -> PerformanceStatistics? in
            guard let times = measurements[label], !times.isEmpty else {
                return nil
            }
            
            let sorted = times.sorted()
            let sum = times.reduce(0, +)
            let average = sum / Double(times.count)
            let minValue = sorted.first!
            let maxValue = sorted.last!
            let median = sorted[sorted.count / 2]
            
            // Calculate 95th percentile
            let p95Index = Int(Double(sorted.count) * 0.95)
            let p95 = sorted[Swift.min(p95Index, sorted.count - 1)]
            
            return PerformanceStatistics(
                label: label,
                count: times.count,
                average: average,
                min: minValue,
                max: maxValue,
                median: median,
                p95: p95
            )
        }
    }
    
    func allStatistics() -> [PerformanceStatistics] {
        return queue.sync {
            return measurements.keys.compactMap { statistics(for: $0) }
        }
    }
    
    // MARK: - Reporting
    
    func printReport() {
        let stats = allStatistics().sorted { $0.average > $1.average }
        
        print("=====================================")
        print("Performance Report")
        print("=====================================")
        
        for stat in stats {
            print("""
            \(stat.label):
              Count: \(stat.count)
              Avg: \(String(format: "%.2f", stat.average * 1000))ms
              Min: \(String(format: "%.2f", stat.min * 1000))ms
              Max: \(String(format: "%.2f", stat.max * 1000))ms
              P95: \(String(format: "%.2f", stat.p95 * 1000))ms
            """)
        }
        
        print("=====================================")
    }
    
    func clear() {
        queue.async { [weak self] in
            self?.measurements.removeAll()
        }
    }
}

// MARK: - Supporting Types

struct TimingToken {
    let label: String
    let startTime: TimeInterval
}

struct PerformanceStatistics {
    let label: String
    let count: Int
    let average: TimeInterval
    let min: TimeInterval
    let max: TimeInterval
    let median: TimeInterval
    let p95: TimeInterval
    
    var averageMs: Double { average * 1000 }
    var minMs: Double { min * 1000 }
    var maxMs: Double { max * 1000 }
    var medianMs: Double { median * 1000 }
    var p95Ms: Double { p95 * 1000 }
}

// MARK: - Global Functions

func measure<T>(_ label: String, block: () throws -> T) rethrows -> T {
    return try PerformanceMonitor.shared.measure(label, block: block)
}

func measureAsync<T>(_ label: String, block: () async throws -> T) async rethrows -> T {
    return try await PerformanceMonitor.shared.measureAsync(label, block: block)
}
