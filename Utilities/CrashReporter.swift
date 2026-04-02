import Foundation
import AppKit
import os

/// Crash and exception reporter
class CrashReporter {
    static let shared = CrashReporter()
    
    private let crashLogDirectory: URL
    private var isSetup = false
    
    private init() {
        crashLogDirectory = AppInfo.shared.logDirectory
            .appendingPathComponent("Crashes")
        
        try? FileManager.default.createDirectory(
            at: crashLogDirectory,
            withIntermediateDirectories: true
        )
    }
    
    // MARK: - Setup
    
    func setup() {
        guard !isSetup else { return }
        isSetup = true
        
        setupExceptionHandler()
        setupSignalHandlers()
    }
    
    private func setupExceptionHandler() {
        NSSetUncaughtExceptionHandler { exception in
            CrashReporter.shared.handleException(exception)
        }
    }
    
    private func setupSignalHandlers() {
        let signals = [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGPIPE]
        
        for signal in signals {
            var action = sigaction()
            action.__sigaction_u.__sa_handler = { signal in
                CrashReporter.shared.handleSignal(signal)
            }
            sigaction(signal, &action, nil)
        }
    }
    
    // MARK: - Handlers
    
    private func handleException(_ exception: NSException) {
        let report = generateCrashReport(
            type: "Exception",
            reason: exception.reason ?? "Unknown",
            stackTrace: exception.callStackSymbols
        )
        
        saveCrashReport(report)
        logCrash("Exception: \(exception.name.rawValue)")
    }
    
    private func handleSignal(_ signal: Int32) {
        let signalName = signalName(for: signal)
        let report = generateCrashReport(
            type: "Signal",
            reason: signalName,
            stackTrace: Thread.callStackSymbols
        )
        
        saveCrashReport(report)
        logCrash("Signal: \(signalName)")
        
        // Re-raise signal for system handler
        Darwin.signal(signal, SIG_DFL)
        raise(signal)
    }
    
    // MARK: - Report Generation
    
    private func generateCrashReport(
        type: String,
        reason: String,
        stackTrace: [String]
    ) -> CrashReport {
        return CrashReport(
            timestamp: Date(),
            type: type,
            reason: reason,
            stackTrace: stackTrace,
            appVersion: AppInfo.shared.fullVersion,
            osVersion: AppInfo.shared.macOSVersion,
            systemInfo: collectSystemInfo()
        )
    }
    
    private func collectSystemInfo() -> [String: Any] {
        return [
            "machine": AppInfo.shared.machineName,
            "memory": MemoryManager.shared.formattedMemoryUsage(),
            "uptime": AppInfo.shared.systemUptime,
            "launchCount": AppInfo.shared.launchCount
        ]
    }
    
    // MARK: - Persistence
    
    private func saveCrashReport(_ report: CrashReport) {
        let filename = "crash-\(Int(report.timestamp.timeIntervalSince1970)).txt"
        let fileURL = crashLogDirectory.appendingPathComponent(filename)
        
        let content = report.formatted()
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    func getRecentCrashes(limit: Int = 10) -> [CrashReport] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: crashLogDirectory,
            includingPropertiesForKeys: [.creationDateKey]
        ) else {
            return []
        }
        
        let sorted = files.sorted {
            let date1 = (try? $0.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            let date2 = (try? $1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            return date1 > date2
        }
        
        return sorted.prefix(limit).compactMap { url in
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
            return CrashReport.parse(from: content)
        }
    }
    
    func clearOldCrashes(olderThan days: Int = 30) {
        guard let files = try? FileManager.default.contentsOfDirectory(at: crashLogDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        for file in files {
            if let date = (try? file.resourceValues(forKeys: [.creationDateKey]))?.creationDate,
               date < cutoffDate {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
    
    // MARK: - Utilities
    
    private func signalName(for signal: Int32) -> String {
        switch signal {
        case SIGABRT: return "SIGABRT"
        case SIGILL: return "SIGILL"
        case SIGSEGV: return "SIGSEGV"
        case SIGFPE: return "SIGFPE"
        case SIGBUS: return "SIGBUS"
        case SIGPIPE: return "SIGPIPE"
        default: return "Signal \(signal)"
        }
    }
    
    private func logCrash(_ message: String) {
        let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "CrashReporter")
        logger.error("\(message, privacy: .public)")
    }
}

// MARK: - Crash Report

struct CrashReport {
    let timestamp: Date
    let type: String
    let reason: String
    let stackTrace: [String]
    let appVersion: String
    let osVersion: String
    let systemInfo: [String: Any]
    
    func formatted() -> String {
        var output = """
        =====================================
        CRASH REPORT
        =====================================
        Date: \(timestamp)
        Type: \(type)
        Reason: \(reason)
        
        App Version: \(appVersion)
        OS Version: \(osVersion)
        
        System Info:
        """
        
        for (key, value) in systemInfo {
            output += "\n  \(key): \(value)"
        }
        
        output += "\n\nStack Trace:\n"
        for (index, frame) in stackTrace.enumerated() {
            output += "\n\(index): \(frame)"
        }
        
        output += "\n\n====================================="
        
        return output
    }
    
    static func parse(from content: String) -> CrashReport? {
        // Simplified parsing - in real implementation, would parse all fields
        return nil
    }
}
