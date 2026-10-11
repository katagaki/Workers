import CloudflareKit
import Foundation

nonisolated enum SharedAccountStore {
    static let groupID = "group.com.tsubuzaki.Workers"
    static var defaults: UserDefaults { UserDefaults(suiteName: groupID) ?? .standard }

    static func prepare() {
        for key in ["SavedTokens", "SelectedTokenID", "SelectedAccountID", "DemoMode"] {
            if defaults.object(forKey: key) == nil, let value = UserDefaults.standard.object(forKey: key) {
                defaults.set(value, forKey: key)
            }
            UserDefaults.standard.removeObject(forKey: key)
        }
        if ProcessInfo.processInfo.arguments.contains("-DemoMode"), UserDefaults.standard.bool(forKey: "DemoMode") {
            defaults.set(true, forKey: "DemoMode")
        }
        guard !defaults.bool(forKey: "DemoMode") else { return }
        for token in tokens {
            KeychainStore.migrate(token.keychainKey)
        }
    }

    static var tokens: [SavedToken] {
        guard let data = defaults.data(forKey: "SavedTokens") else { return [] }
        return (try? JSONDecoder().decode([SavedToken].self, from: data)) ?? []
    }

    static func storeAccountIDs(_ identifiers: [String], for tokenID: UUID) {
        defaults.set(identifiers, forKey: "AccountIDs.\(tokenID)")
    }

    static func client(accountID: String) throws -> CloudflareClient {
        if defaults.bool(forKey: "DemoMode") { return .demo() }
        let selectedID = defaults.string(forKey: "SelectedTokenID")
        let owners = tokens.sorted { $0.id.uuidString == selectedID && $1.id.uuidString != selectedID }
        for token in owners where (defaults.stringArray(forKey: "AccountIDs.\(token.id)") ?? []).contains(accountID) {
            if let value = KeychainStore.read(token.keychainKey) { return CloudflareClient(token: value) }
        }
        throw IntentError.notSignedIn
    }

    static var accountIDs: [String] {
        if defaults.bool(forKey: "DemoMode") {
            return defaults.string(forKey: "SelectedAccountID").map { [$0] } ?? []
        }
        return Array(Set(tokens.flatMap { defaults.stringArray(forKey: "AccountIDs.\($0.id)") ?? [] })).sorted()
    }

    static func removeResources(for tokenID: UUID) {
        let identifiers = defaults.stringArray(forKey: "AccountIDs.\(tokenID)") ?? []
        defaults.removeObject(forKey: "AccountIDs.\(tokenID)")
        for accountID in identifiers where !accountIDs.contains(accountID) {
            defaults.removeObject(forKey: "Workers.\(accountID)")
            defaults.removeObject(forKey: "Zones.\(accountID)")
            for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("Widget.\(accountID)/") { defaults.removeObject(forKey: key) }
        }
    }

    static func clearResources() {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("Workers.") || key.hasPrefix("Zones.") || key.hasPrefix("AccountIDs.") || key.hasPrefix("Widget.") || key.hasPrefix("SecurityLevel.") {
            defaults.removeObject(forKey: key)
        }
    }

    static func store<Value: Encodable>(_ value: Value, key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
    }

    static func value<Value: Decodable>(key: String, as type: Value.Type) -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
