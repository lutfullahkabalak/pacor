import Foundation
import Security

enum KeychainService {
    private static let service = "tr.abapnews.pacor"

    static var token: String? {
        get { read(key: "token") }
        set { write(key: "token", value: newValue) }
    }

    static var username: String? {
        get { read(key: "username") }
        set { write(key: "username", value: newValue) }
    }

    static var userId: Int? {
        get {
            guard let value = read(key: "user_id") else { return nil }
            return Int(value)
        }
        set {
            if let newValue {
                write(key: "user_id", value: String(newValue))
            } else {
                delete(key: "user_id")
            }
        }
    }

    static var isAuthenticated: Bool {
        guard let token, !token.isEmpty else { return false }
        return true
    }

    @discardableResult
    static func saveSession(_ response: AuthResponse) -> Bool {
        guard !response.token.isEmpty else { return false }
        let tokenSaved = write(key: "token", value: response.token)
        _ = write(key: "username", value: response.username)
        _ = write(key: "user_id", value: String(response.userId))
        return tokenSaved
    }

    static func clearSession() {
        delete(key: "token")
        delete(key: "username")
        delete(key: "user_id")
    }

    private static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    private static func write(key: String, value: String?) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        if value == nil {
            SecItemDelete(query as CFDictionary)
            return true
        }

        guard let value, let data = value.data(using: .utf8) else { return false }

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return true
        }

        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
        }

        return false
    }

    private static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
