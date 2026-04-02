import Foundation

/// Protocol for XPC helper service
@objc protocol XPCHelperProtocol {
    /// Check if helper is running
    func ping(completion: @escaping (Bool) -> Void)
    
    /// Get system information
    func getSystemInfo(completion: @escaping ([String: Any]) -> Void)
    
    /// Execute privileged task
    func executePrivilegedTask(_ command: String, arguments: [String], completion: @escaping (Int32, String, String) -> Void)
    
    /// Monitor system events
    func startMonitoring(completion: @escaping (Bool) -> Void)
    func stopMonitoring(completion: @escaping (Bool) -> Void)
    
    /// File operations
    func copyFile(from: String, to: String, completion: @escaping (Bool, String?) -> Void)
    func moveFile(from: String, to: String, completion: @escaping (Bool, String?) -> Void)
    func deleteFile(at path: String, completion: @escaping (Bool, String?) -> Void)
    
    /// Permission management
    func requestAccessibilityPermissions(completion: @escaping (Bool) -> Void)
    func checkPermissions(completion: @escaping ([String: Bool]) -> Void)
    
    // MARK: - Accessibility Authorization
    func isAccessibilityAuthorized(completion: @escaping (Bool) -> Void)
    func requestAccessibilityAuthorization()
    func ensureAccessibilityAuthorization(_ promptIfNeeded: Bool, completion: @escaping (Bool) -> Void)
    
    // MARK: - Keyboard Brightness
    func isKeyboardBrightnessAvailable(completion: @escaping (Bool) -> Void)
    func currentKeyboardBrightness(completion: @escaping (NSNumber?) -> Void)
    func setKeyboardBrightness(_ value: Float, completion: @escaping (Bool) -> Void)
    
    // MARK: - Screen Brightness
    func isScreenBrightnessAvailable(completion: @escaping (Bool) -> Void)
    func currentScreenBrightness(completion: @escaping (NSNumber?) -> Void)
    func setScreenBrightness(_ value: Float, completion: @escaping (Bool) -> Void)
}

/// Helper service errors
enum XPCHelperError: Error {
    case connectionFailed
    case helperNotInstalled
    case permissionDenied
    case taskFailed(reason: String)
    case invalidResponse
}

/// Helper installation status
enum XPCHelperStatus {
    case notInstalled
    case installed
    case running
    case error(Error)
}
