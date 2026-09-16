import Foundation
import Security

enum KeychainStore {
    private static let service = "cn.msadream.AIServerClient"
    static func save(_ token: String) throws {
        let data = Data(token.utf8)
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: "api-token"]
        SecItemDelete(query as CFDictionary)
        var insert = query; insert[kSecValueData as String] = data; insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else { throw KeychainError.saveFailed }
    }
    static func read() -> String? { let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: "api-token", kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]; var result: CFTypeRef?; guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }; return String(data: data, encoding: .utf8) }
    static func delete() { SecItemDelete([kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: "api-token"] as CFDictionary) }
    enum KeychainError: Error { case saveFailed }
}
