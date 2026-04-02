//
//  EncryptionService.swift
//  Mac灵动岛
//
//  AES-256-GCM encryption for clipboard data using CryptoKit
//

import Foundation
import Combine
import CryptoKit

final class EncryptionService {
    
    private let keychainStore = KeychainStore()
    private var cachedKey: SymmetricKey?
    
    // MARK: - Initialization
    
    /// Setup encryption (generate key if needed)
    func setup() throws {
        if !keychainStore.keyExists() {
            // Generate new key
            let keyData = keychainStore.generateKey()
            try keychainStore.saveKey(keyData)
        }
        
        // Load and cache key
        let keyData = try keychainStore.loadKey()
        cachedKey = SymmetricKey(data: keyData)
    }
    
    /// Disable encryption (delete key)
    func disable() throws {
        try keychainStore.deleteKey()
        cachedKey = nil
    }
    
    /// Check if encryption is enabled
    func isEnabled() -> Bool {
        return keychainStore.keyExists()
    }
    
    // MARK: - Encryption
    
    /// Encrypt data using AES-256-GCM
    func encrypt(_ data: Data) throws -> Data {
        guard let key = cachedKey else {
            throw EncryptionError.keyNotLoaded
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        
        return combined
    }
    
    /// Decrypt data using AES-256-GCM
    func decrypt(_ data: Data) throws -> Data {
        guard let key = cachedKey else {
            throw EncryptionError.keyNotLoaded
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decrypted = try AES.GCM.open(sealedBox, using: key)
        
        return decrypted
    }
    
    // MARK: - Convenience Methods
    
    /// Encrypt string to base64
    func encryptString(_ string: String) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidInput
        }
        
        let encrypted = try encrypt(data)
        return encrypted.base64EncodedString()
    }
    
    /// Decrypt base64 string
    func decryptString(_ base64String: String) throws -> String {
        guard let data = Data(base64Encoded: base64String) else {
            throw EncryptionError.invalidInput
        }
        
        let decrypted = try decrypt(data)
        
        guard let string = String(data: decrypted, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        
        return string
    }
    
    // MARK: - Errors
    
    enum EncryptionError: Error, LocalizedError {
        case keyNotLoaded
        case encryptionFailed
        case decryptionFailed
        case invalidInput
        
        var errorDescription: String? {
            switch self {
            case .keyNotLoaded:
                return "Encryption key not loaded"
            case .encryptionFailed:
                return "Failed to encrypt data"
            case .decryptionFailed:
                return "Failed to decrypt data"
            case .invalidInput:
                return "Invalid input data"
            }
        }
    }
}
