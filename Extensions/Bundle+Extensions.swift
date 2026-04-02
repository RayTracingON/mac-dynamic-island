import Foundation

extension Bundle {
    /// App name
    var appName: String {
        return infoDictionary?["CFBundleName"] as? String ?? "Unknown"
    }
    
    /// App version
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    /// Build number
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// Bundle identifier
    var identifier: String {
        return bundleIdentifier ?? "unknown"
    }
    
    /// Full version string
    var fullVersion: String {
        return "\(appVersion) (\(buildNumber))"
    }
}
