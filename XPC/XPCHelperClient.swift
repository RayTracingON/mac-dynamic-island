import Foundation
import AppKit
import os

/// Client for communicating with XPC helper service
class XPCHelperClient {
    static let shared = XPCHelperClient()
    
    private var connection: NSXPCConnection?
    private let serviceName = "com.mac灵动岛.XPCHelper"
    
    private init() {
        setupConnection()
    }
    
    deinit {
        connection?.invalidate()
    }
    
    // MARK: - Connection Management
    
    private func setupConnection() {
        let newConnection = NSXPCConnection(serviceName: serviceName)
        let interface = NSXPCInterface(with: XPCHelperProtocol.self)
        
        // SECURITY FIX: Define allowed classes strictly to prevent NSXPCDecoder spam/freeze
        let classes: [AnyClass] = [
            NSString.self, NSNumber.self, NSDictionary.self, NSArray.self, 
            NSDate.self, NSData.self, NSURL.self
        ]
        let allowedClasses = NSSet(array: classes) as! Set<AnyHashable>
        
        // Apply whitelist to methods returning objects (index 0 of reply block)
        let selectorMap: [Selector] = [
            #selector(XPCHelperProtocol.getSystemInfo(completion:)),
            #selector(XPCHelperProtocol.checkPermissions(completion:)),
            #selector(XPCHelperProtocol.currentKeyboardBrightness(completion:)),
            #selector(XPCHelperProtocol.currentScreenBrightness(completion:))
        ]
        
        for selector in selectorMap {
            interface.setClasses(allowedClasses, for: selector, argumentIndex: 0, ofReply: true)
        }
        
        newConnection.remoteObjectInterface = interface
        
        newConnection.invalidationHandler = { [weak self] in
            let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "XPCHelper")
            logger.warning("XPC connection invalidated")
            self?.connection = nil
        }
        
        newConnection.interruptionHandler = { [weak self] in
            let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "XPCHelper")
            logger.warning("XPC connection interrupted")
            self?.setupConnection()
        }
        
        newConnection.resume()
        self.connection = newConnection
    }
    
    private func getProxy() -> XPCHelperProtocol? {
        if connection == nil {
            setupConnection()
        }
        return connection?.remoteObjectProxyWithErrorHandler { error in
            let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "XPCHelper")
            logger.error("XPC proxy error: \(error.localizedDescription, privacy: .public)")
        } as? XPCHelperProtocol
    }
    
    // MARK: - Accessibility Authorization
    
    func isAccessibilityAuthorized() async -> Bool {
        await withCheckedContinuation { continuation in
            guard let proxy = getProxy() else {
                continuation.resume(returning: AXIsProcessTrusted())
                return
            }
            
            proxy.isAccessibilityAuthorized { authorized in
                continuation.resume(returning: authorized)
            }
        }
    }
    
    func requestAccessibilityAuthorization() {
        guard let proxy = getProxy() else {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            return
        }
        
        proxy.requestAccessibilityAuthorization()
    }
    
    func ensureAccessibilityAuthorization(promptIfNeeded: Bool) async -> Bool {
        await withCheckedContinuation { continuation in
            guard let proxy = getProxy() else {
                continuation.resume(returning: AXIsProcessTrusted())
                return
            }
            
            proxy.ensureAccessibilityAuthorization(promptIfNeeded) { authorized in
                continuation.resume(returning: authorized)
            }
        }
    }
    
    // MARK: - Keyboard Brightness
    
    func isKeyboardBrightnessAvailable() async -> Bool {
        await withCheckedContinuation { continuation in
            guard let proxy = getProxy() else {
                continuation.resume(returning: false)
                return
            }
            
            proxy.isKeyboardBrightnessAvailable { available in
                continuation.resume(returning: available)
            }
        }
    }
    
    func currentKeyboardBrightness() async -> Float? {
        await withCheckedContinuation { continuation in
            guard let proxy = getProxy() else {
                continuation.resume(returning: nil)
                return
            }
            
            proxy.currentKeyboardBrightness { value in
                continuation.resume(returning: value?.floatValue)
            }
        }
    }
    
    func setKeyboardBrightness(_ value: Float) async -> Bool {
        await withCheckedContinuation { continuation in
            guard let proxy = getProxy() else {
                continuation.resume(returning: false)
                return
            }
            
            proxy.setKeyboardBrightness(value) { success in
                continuation.resume(returning: success)
            }
        }
    }
    
    // MARK: - Screen Brightness
    
    func isScreenBrightnessAvailable() async -> Bool {
        await withCheckedContinuation { continuation in
            guard let proxy = getProxy() else {
                continuation.resume(returning: false)
                return
            }
            
            proxy.isScreenBrightnessAvailable { available in
                continuation.resume(returning: available)
            }
        }
    }
    
    func currentScreenBrightness() async -> Float? {
        await withCheckedContinuation { continuation in
            guard let proxy = getProxy() else {
                continuation.resume(returning: nil)
                return
            }
            
            proxy.currentScreenBrightness { value in
                continuation.resume(returning: value?.floatValue)
            }
        }
    }
    
    func setScreenBrightness(_ value: Float) async -> Bool {
        await withCheckedContinuation { continuation in
            guard let proxy = getProxy() else {
                continuation.resume(returning: false)
                return
            }
            
            proxy.setScreenBrightness(value) { success in
                continuation.resume(returning: success)
            }
        }
    }
    
    // MARK: - Legacy Support
    
    func stopMonitoringAccessibilityAuthorization() {
        // No-op for now as monitoring is handled internally or via polling if needed
    }
}
