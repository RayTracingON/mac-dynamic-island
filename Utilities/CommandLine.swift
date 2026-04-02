import Foundation

/// Debug command line interface
class CommandLineInterface {
    static let shared = CommandLineInterface()
    
    private var commands: [String: Command] = [:]
    
    private init() {
        registerDefaultCommands()
    }
    
    // MARK: - Command Registration
    
    func register(_ command: Command) {
        commands[command.name] = command
    }
    
    private func registerDefaultCommands() {
        register(HelpCommand())
        register(StatusCommand())
        register(ClearCacheCommand())
        register(LogsCommand())
        register(ConfigCommand())
        register(DebugCommand())
        register(PerformanceCommand())
    }
    
    // MARK: - Execution
    
    func execute(_ input: String) -> String {
        let components = input.split(separator: " ").map(String.init)
        guard let commandName = components.first else {
            return "No command specified. Type 'help' for available commands."
        }
        
        let args = Array(components.dropFirst())
        
        guard let command = commands[commandName] else {
            return "Unknown command: \(commandName). Type 'help' for available commands."
        }
        
        return command.execute(args: args)
    }
    
    func availableCommands() -> [Command] {
        return Array(commands.values).sorted { $0.name < $1.name }
    }
    
    /// Get command by name (for help command)
    func command(named name: String) -> Command? {
        return commands[name]
    }
}

// MARK: - Command Protocol

protocol Command {
    var name: String { get }
    var description: String { get }
    var usage: String { get }
    
    func execute(args: [String]) -> String
}

// MARK: - Built-in Commands

struct HelpCommand: Command {
    let name = "help"
    let description = "Show available commands"
    let usage = "help [command]"
    
    func execute(args: [String]) -> String {
        if let commandName = args.first {
            if let command = CommandLineInterface.shared.command(named: commandName) {
                return """
                \(command.name): \(command.description)
                Usage: \(command.usage)
                """
            } else {
                return "Unknown command: \(commandName)"
            }
        }
        
        var output = "Available commands:\n\n"
        for command in CommandLineInterface.shared.availableCommands() {
            output += "  \(command.name.padding(toLength: 15, withPad: " ", startingAt: 0)) \(command.description)\n"
        }
        output += "\nType 'help [command]' for more information about a specific command."
        return output
    }
}

struct StatusCommand: Command {
    let name = "status"
    let description = "Show app status"
    let usage = "status"
    
    func execute(args: [String]) -> String {
        return """
        App Status:
        - Version: \(AppInfo.shared.fullVersion)
        - Memory: \(MemoryManager.shared.formattedMemoryUsage())
        - Uptime: \(AppInfo.shared.systemUptime)
        - Launch Count: \(AppInfo.shared.launchCount)
        """
    }
}

struct ClearCacheCommand: Command {
    let name = "clear-cache"
    let description = "Clear all caches"
    let usage = "clear-cache"
    
    func execute(args: [String]) -> String {
        MemoryManager.shared.clearCaches()
        return "Cache cleared successfully"
    }
}

struct LogsCommand: Command {
    let name = "logs"
    let description = "Show recent logs"
    let usage = "logs [count]"
    
    func execute(args: [String]) -> String {
        let count = args.first.flatMap(Int.init) ?? 10
        return "Showing last \(count) log entries..."
        // Implementation would read from log files
    }
}

struct ConfigCommand: Command {
    let name = "config"
    let description = "Show configuration"
    let usage = "config"
    
    func execute(args: [String]) -> String {
        BuildConfig.printConfiguration()
        return ""
    }
}

struct DebugCommand: Command {
    let name = "debug"
    let description = "Toggle debug mode"
    let usage = "debug [on|off]"
    
    func execute(args: [String]) -> String {
        if let arg = args.first {
            let enabled = arg.lowercased() == "on"
            UserDefaults.standard.set(enabled, forKey: "debugMode")
            return "Debug mode \(enabled ? "enabled" : "disabled")"
        }
        
        let isEnabled = UserDefaults.standard.bool(forKey: "debugMode")
        return "Debug mode is currently \(isEnabled ? "enabled" : "disabled")"
    }
}

struct PerformanceCommand: Command {
    let name = "performance"
    let description = "Show performance metrics"
    let usage = "performance"
    
    func execute(args: [String]) -> String {
        return """
        Performance Metrics:
        - Memory: \(MemoryManager.shared.formattedMemoryUsage())
        - Active Tasks: \(TaskQueue.shared.activeTaskCount)
        - Launch Count: \(AnalyticsManager.shared.getLaunchCount())
        """
    }
}
