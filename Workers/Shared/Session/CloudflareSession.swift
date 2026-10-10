import CloudflareKit
import Foundation
import Observation

@Observable
final class CloudflareSession {
    nonisolated private static let tokenKey = "APIToken"
    nonisolated private static let selectedAccountKey = "SelectedAccountID"
    nonisolated private static let demoModeKey = "DemoMode"

    private(set) var client: CloudflareClient?
    private(set) var accounts = CachedResource<[Account]>(key: "accounts")

    var selectedAccountId: String? {
        didSet {
            UserDefaults.standard.set(selectedAccountId, forKey: Self.selectedAccountKey)
        }
    }

    init() {
        client = Self.storedClient()
        selectedAccountId = Self.storedSelectedAccountId()
    }

    nonisolated static func storedClient() -> CloudflareClient? {
        if UserDefaults.standard.bool(forKey: demoModeKey) {
            return .demo()
        } else if let token = KeychainStore.read(tokenKey) {
            return CloudflareClient(token: token)
        }
        return nil
    }

    nonisolated static func storedSelectedAccountId() -> String? {
        UserDefaults.standard.string(forKey: selectedAccountKey)
    }

    var isSignedIn: Bool {
        client != nil
    }

    var isDemo: Bool {
        client?.isDemo ?? false
    }

    var selectedAccount: Account? {
        accounts.value?.first { $0.id == selectedAccountId } ?? accounts.value?.first
    }

    func signIn(token: String) async throws {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = CloudflareClient(token: trimmedToken)
        let fetchedAccounts = try await candidate.accounts()
        KeychainStore.save(trimmedToken, for: Self.tokenKey)
        client = candidate
        await accounts.refresh { fetchedAccounts }
        if selectedAccountId == nil || !fetchedAccounts.contains(where: { $0.id == selectedAccountId }) {
            selectedAccountId = fetchedAccounts.first?.id
        }
    }

    func startDemo() async {
        DiskCache.shared.clear()
        accounts = CachedResource(key: "accounts")
        let demoClient = CloudflareClient.demo()
        UserDefaults.standard.set(true, forKey: Self.demoModeKey)
        client = demoClient
        await accounts.refresh { try await demoClient.accounts() }
        selectedAccountId = accounts.value?.first?.id
    }

    func refreshAccounts() async {
        guard let client else { return }
        await accounts.refresh { try await client.accounts() }
        if selectedAccount?.id != selectedAccountId {
            selectedAccountId = selectedAccount?.id
        }
    }

    func signOut() {
        UserDefaults.standard.set(false, forKey: Self.demoModeKey)
        KeychainStore.delete(Self.tokenKey)
        client = nil
        selectedAccountId = nil
        DiskCache.shared.clear()
        accounts = CachedResource(key: "accounts")
    }
}
