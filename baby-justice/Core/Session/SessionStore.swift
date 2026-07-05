import Foundation
import Observation

@Observable
final class SessionStore {
    static let shared = SessionStore()

    private static let tokenKey = "auth_token"
    private static let roleKey = "session_role"
    private static let accountIdKey = "session_account_id"
    private static let displayNameKey = "session_display_name"
    private static let childCodeKey = "session_child_code"
    private static let familyNameKey = "session_family_name"

    var token: String?
    var role: Role?
    var accountId: Int64?
    var displayName: String = ""
    var childCode: String?
    var familyName: String?

    var isLoggedIn: Bool { token != nil && role != nil }
    var isParent: Bool { role == .parent }
    var isChild: Bool { role == .child }

    private init() {
        let defaults = UserDefaults.standard
        token = KeychainStorage.load(forKey: Self.tokenKey)
        role = defaults.string(forKey: Self.roleKey).flatMap(Role.init(rawValue:))
        accountId = (defaults.object(forKey: Self.accountIdKey) as? NSNumber)?.int64Value
        displayName = defaults.string(forKey: Self.displayNameKey) ?? ""
        childCode = defaults.string(forKey: Self.childCodeKey)
        familyName = defaults.string(forKey: Self.familyNameKey)
    }

    func startSession(_ auth: AuthResponse) {
        token = auth.token
        role = auth.role
        accountId = auth.accountId
        displayName = auth.displayName
        childCode = auth.childCode
        familyName = auth.familyName
        KeychainStorage.save(auth.token, forKey: Self.tokenKey)
        let defaults = UserDefaults.standard
        defaults.set(auth.role.rawValue, forKey: Self.roleKey)
        defaults.set(NSNumber(value: auth.accountId), forKey: Self.accountIdKey)
        defaults.set(auth.displayName, forKey: Self.displayNameKey)
        setOrRemove(auth.childCode, forKey: Self.childCodeKey, in: defaults)
        setOrRemove(auth.familyName, forKey: Self.familyNameKey, in: defaults)
    }

    func logout() {
        ImageCache.shared.removeAll()
        token = nil
        role = nil
        accountId = nil
        displayName = ""
        childCode = nil
        familyName = nil
        KeychainStorage.delete(forKey: Self.tokenKey)
        let defaults = UserDefaults.standard
        for key in [Self.roleKey, Self.accountIdKey, Self.displayNameKey, Self.childCodeKey, Self.familyNameKey] {
            defaults.removeObject(forKey: key)
        }
    }

    private func setOrRemove(_ value: String?, forKey key: String, in defaults: UserDefaults) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
