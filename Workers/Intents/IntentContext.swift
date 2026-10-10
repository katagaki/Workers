import CloudflareKit
import Foundation

nonisolated enum IntentContext {
    static func client() throws -> CloudflareClient {
        guard let client = CloudflareSession.storedClient() else { throw IntentError.notSignedIn }
        return client
    }

    static func selectedAccountId(client: CloudflareClient) async throws -> String {
        if let accountId = CloudflareSession.storedSelectedAccountId() {
            return accountId
        }
        guard let accountId = try await client.accounts().first?.id else { throw IntentError.noAccount }
        return accountId
    }
}
