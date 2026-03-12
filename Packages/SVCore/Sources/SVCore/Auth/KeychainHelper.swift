import Foundation
import Security

/// Securely stores and retrieves the Apple user identifier in the iOS Keychain.
///
/// Uses `kSecClassGenericPassword` with a fixed service/account key pair.
/// All operations are synchronous (Security framework is thread-safe),
/// so this is a `final class` conforming to `Sendable` — not an `actor`.
///
/// - Important: The Keychain persists across app reinstalls. Data is only removed
///   when the user explicitly signs out or resets the device.
public final class KeychainHelper: Sendable {
    // MARK: - Constants

    private static let service = "com.survibe.auth"
    private static let accountKey = "apple_user_identifier"

    // MARK: - Errors

    /// Errors thrown by Keychain operations.
    public enum KeychainError: LocalizedError, Sendable {
        /// The item was not found in the Keychain.
        case itemNotFound
        /// A Keychain operation failed with an OS status code.
        case operationFailed(OSStatus)
        /// The stored data could not be decoded as UTF-8.
        case dataConversionFailed

        public var errorDescription: String? {
            switch self {
            case .itemNotFound:
                "No saved credential found in Keychain."
            case .operationFailed(let status):
                "Keychain operation failed with status: \(status)"
            case .dataConversionFailed:
                "Failed to decode Keychain data as UTF-8 string."
            }
        }
    }

    // MARK: - Public Methods

    /// Stores the Apple user identifier in the Keychain.
    ///
    /// If an existing entry is found, it is updated in place.
    ///
    /// - Parameter userIdentifier: The stable Apple ID identifier string.
    /// - Throws: `KeychainError.operationFailed` if the store/update fails.
    public static func storeUserIdentifier(_ userIdentifier: String) throws {
        guard let data = userIdentifier.data(using: .utf8) else {
            throw KeychainError.dataConversionFailed
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountKey,
        ]

        // Try to update existing item first
        let attributes: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecItemNotFound {
            // No existing item — add new
            var addQuery = query
            addQuery[kSecValueData as String] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.operationFailed(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw KeychainError.operationFailed(updateStatus)
        }
    }

    /// Retrieves the stored Apple user identifier from the Keychain.
    ///
    /// - Returns: The Apple user identifier string.
    /// - Throws: `KeychainError.itemNotFound` if no credential is stored,
    ///           `KeychainError.dataConversionFailed` if the data is corrupt.
    public static func retrieveUserIdentifier() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.operationFailed(status)
        }

        guard let data = result as? Data, let identifier = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionFailed
        }

        return identifier
    }

    /// Deletes the stored Apple user identifier from the Keychain.
    ///
    /// - Throws: `KeychainError.operationFailed` if the deletion fails.
    ///           Does NOT throw if the item was already absent.
    public static func deleteUserIdentifier() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountKey,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.operationFailed(status)
        }
    }
}
