//
//  KeychainStore.swift
//  Mac灵动岛
//
//  Secure encryption key storage using macOS Keychain Services
//

import Foundation
import Combine
import Security

final class KeychainStore {
    
    // MARK: - Configuration
    
    private let service = "com.maclingdonggao.clipboard.encryption"
    private let account = "clipboard_master_key"
    
    // MARK: - Key Operations
    
    /// Save encryption key to Keychain
    func saveKey(_ key: Data) throws {
        // Delete existing key first (if any)
        try? deleteKey()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.failedToSave(status)
        }
    }
    
    /// Load encryption key from Keychain
    func loadKey() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.keyNotFound
        }
        
        return data
    }
    
    /// Delete encryption key from Keychain
    func deleteKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Ignore errSecItemNotFound
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.failedToDelete(status)
        }
    }
    
    /// Check if key exists
    func keyExists() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Generate new random key (256-bit for AES-256)
    func generateKey() -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        
        guard status == errSecSuccess else {
            // Fallback to Swift's random generator if SecRandom fails
            return Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        }
        
        return Data(bytes)
    }
    
    // MARK: - Errors
    
    enum KeychainError: Error, LocalizedError {
        case failedToSave(OSStatus)
        case keyNotFound
        case failedToDelete(OSStatus)
        
        var errorDescription: String? {
            switch self {
            case .failedToSave(let status):
                return "Failed to save key to Keychain (status: \(status))"
            case .keyNotFound:
                return "Encryption key not found in Keychain"
            case .failedToDelete(let status):
                return "Failed to delete key from Keychain (status: \(status))"
            }
        }
    }
}
