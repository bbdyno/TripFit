import Domain
import Foundation
import Security

@MainActor
final class PendingInviteStore {
    static let didChangeNotification = Notification.Name("tripfit.pendingInvite.didChange")

    private let service = "com.bbdyno.app.tripFit.pending-invite"
    private let account = "raw-token"
    private var memoryToken: String?

    var rawToken: String? {
        if let memoryToken { return memoryToken }
        guard let data = keychainData(), let token = String(data: data, encoding: .utf8) else { return nil }
        memoryToken = token
        return token
    }

    @discardableResult
    func accept(url: URL) -> Bool {
        guard let token = InviteLinkParser.rawToken(from: url) else { return false }
        memoryToken = token
        saveToKeychain(Data(token.utf8))
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
        return true
    }

    func clear() {
        memoryToken = nil
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        SecItemDelete(query as CFDictionary)
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }

    private func saveToKeychain(_ data: Data) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        SecItemDelete(query as CFDictionary)
        var insert = query
        insert[kSecValueData] = data
        insert[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(insert as CFDictionary, nil)
    }

    private func keychainData() -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }
}
