// KeychainHelper.swift
// Revless
//
// Lightweight, synchronous Keychain wrapper for storing the JWT token.
// Uses kSecClassGenericPassword — the appropriate class for arbitrary secrets.
// Never store JWTs in UserDefaults; Keychain entries survive app reinstalls
// and are protected by the device Secure Enclave.

import Foundation
import Security

enum KeychainHelper {

    private static let service = Bundle.main.bundleIdentifier ?? "com.revless.app"

    // MARK: - Public API

    /// Persist a string value. Overwrites any existing entry for the same key.
    @discardableResult
    static func save(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        delete(key) // Remove stale entry before writing
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      key,
            kSecValueData:        data,
            kSecAttrAccessible:   kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    /// Retrieve a stored string value, or nil if not found.
    static func get(_ key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:        kSecClassGenericPassword,
            kSecAttrService:  service,
            kSecAttrAccount:  key,
            kSecReturnData:   true,
            kSecMatchLimit:   kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Delete a stored entry.
    @discardableResult
    static func delete(_ key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}

// MARK: - Well-known keys

extension KeychainHelper {
    static let jwtTokenKey = "revless.jwt_token"
}
