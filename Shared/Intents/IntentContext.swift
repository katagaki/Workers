import CloudflareKit
import Foundation

nonisolated enum IntentContext {
    static func client() throws -> CloudflareClient {
        if SharedAccountStore.defaults.bool(forKey: "DemoMode") { return .demo() }
        guard let accountID = SharedAccountStore.defaults.string(forKey: "SelectedAccountID") else { throw IntentError.notSignedIn }
        return try client(accountId: accountID)
    }

    static func client(accountId: String) throws -> CloudflareClient {
        try SharedAccountStore.client(accountID: accountId)
    }

    static func client(zone: ZoneEntity) throws -> CloudflareClient {
        guard let accountID = zone.accountId else { throw IntentError.zoneNotFound }
        return try client(accountId: accountID)
    }

    static func selectedAccountId(client: CloudflareClient) async throws -> String {
        if let accountId = SharedAccountStore.defaults.string(forKey: "SelectedAccountID") {
            return accountId
        }
        guard let accountId = try await client.accounts().first?.id else { throw IntentError.noAccount }
        return accountId
    }
}
