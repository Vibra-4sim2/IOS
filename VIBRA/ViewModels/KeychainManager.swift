//
//  KeychainManager.swift
//  VIBRA
//
//  A minimal Keychain helper to securely store the JWT used by LoginViewModel.
//

import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()
    private init() {}

    // Customize service/key names if needed
    private let service = Bundle.main.bundleIdentifier ?? "VIBRA"
    private let account = "auth.jwt"

    enum KeychainError: Error {
        case unexpectedStatus(OSStatus)
        case dataEncodingFailed
        case dataDecodingFailed
        case notFound
    }

    // Save or update the JWT token in Keychain
    func saveJWT(token: String) throws {
        guard let data = token.data(using: .utf8) else { throw KeychainError.dataEncodingFailed }

        // Query for existing item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        // Attributes to update or create
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        // Try update first
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            // Create new item
            var addQuery = query
            addQuery.merge(attributes) { _, new in new }
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError.unexpectedStatus(addStatus) }
        default:
            throw KeychainError.unexpectedStatus(updateStatus)
        }
    }

    // Retrieve the stored JWT token
    func getJWT() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else { throw KeychainError.notFound }
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }

        guard let data = item as? Data, let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataDecodingFailed
        }
        return token
    }

    // Delete the stored JWT token (useful for logout)
    func deleteJWT() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
