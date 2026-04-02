//
//  TouchIDManager.swift
//  Mac灵动岛
//
//  Touch ID / Face ID authentication manager for macOS
//

import Foundation
import LocalAuthentication
import Combine

@MainActor
final class TouchIDManager: ObservableObject {
    
    // MARK: - Published State
    
    @Published var isLocked: Bool = true
    @Published var lastUnlockAt: Date?
    
    // MARK: - Configuration
    
    var sessionTimeout: TimeInterval = 300  // 5 minutes default
    
    // MARK: - Private State
    
    private let context = LAContext()
    
    // MARK: - Availability Check
    
    /// Check if biometric authentication is available
    func canEvaluate() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    // MARK: - Lock/Unlock
    
    /// Lock immediately
    func lock() {
        isLocked = true
        lastUnlockAt = nil
    }
    
    /// Unlock if needed (authenticate if locked, or return true if within timeout)
    func unlockIfNeeded(reason: String) async -> Bool {
        // Check if already unlocked and within timeout
        if !isLocked, let lastUnlock = lastUnlockAt {
            let elapsed = Date().timeIntervalSince(lastUnlock)
            if elapsed < sessionTimeout {
                return true
            }
        }
        
        // Need to authenticate
        let authContext = LAContext()
        
        // Check availability
        var error: NSError?
        guard authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Biometric not available - fail closed
            isLocked = true
            return false
        }
        
        // Authenticate (async, won't block UI)
        do {
            let success = try await authContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                isLocked = false
                lastUnlockAt = Date()
                return true
            } else {
                // Auth failed - remain locked
                isLocked = true
                return false
            }
        } catch {
            // Auth error - fail closed
            isLocked = true
            return false
        }
    }
    
    /// Auto-relock if session timeout exceeded
    func refreshLockStateIfNeeded(now: Date) {
        guard !isLocked, let lastUnlock = lastUnlockAt else { return }
        
        let elapsed = now.timeIntervalSince(lastUnlock)
        if elapsed >= sessionTimeout {
            lock()
        }
    }
}
