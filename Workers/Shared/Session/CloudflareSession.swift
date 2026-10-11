import CloudflareKit
import Foundation
import Observation
import WidgetKit

@Observable
final class CloudflareSession {
    nonisolated private static let legacyTokenKey = "APIToken"
    nonisolated private static let savedTokensKey = "SavedTokens"
    nonisolated private static let selectedTokenKey = "SelectedTokenID"
    nonisolated private static let selectedAccountKey = "SelectedAccountID"
    nonisolated private static let demoModeKey = "DemoMode"

    private(set) var savedTokens: [SavedToken] = []
    private(set) var selectedTokenId: UUID?
    private(set) var client: CloudflareClient?
    private(set) var accountLists: [UUID: CachedResource<[Account]>] = [:]
    private var demoAccounts = CachedResource<[Account]>(key: "accounts-demo")
    private let emptyAccounts = CachedResource<[Account]>(key: "accounts-none")

    var selectedAccountId: String? {
        didSet {
            SharedAccountStore.defaults.set(selectedAccountId, forKey: Self.selectedAccountKey)
        }
    }

    init() {
        SharedAccountStore.prepare()
        Self.migrateLegacyToken()
        savedTokens = Self.storedTokens()
        selectedTokenId = Self.storedSelectedToken()?.id
        accountLists = Dictionary(uniqueKeysWithValues: savedTokens.map { ($0.id, Self.accountList(for: $0.id)) })
        for token in savedTokens {
            if let accounts = accountLists[token.id]?.value { SharedAccountStore.storeAccountIDs(accounts.map(\.id), for: token.id) }
        }
        client = Self.storedClient()
        selectedAccountId = Self.storedSelectedAccountId()
    }

    nonisolated static func storedClient() -> CloudflareClient? {
        if SharedAccountStore.defaults.bool(forKey: demoModeKey) {
            return .demo()
        }
        if let savedToken = storedSelectedToken(), let token = KeychainStore.read(savedToken.keychainKey) {
            return CloudflareClient(token: token)
        }
        if let token = KeychainStore.read(legacyTokenKey) {
            return CloudflareClient(token: token)
        }
        return nil
    }

    nonisolated static func storedSelectedAccountId() -> String? {
        SharedAccountStore.defaults.string(forKey: selectedAccountKey)
    }

    nonisolated private static func storedTokens() -> [SavedToken] {
        guard let data = SharedAccountStore.defaults.data(forKey: savedTokensKey) else { return [] }
        return (try? JSONDecoder().decode([SavedToken].self, from: data)) ?? []
    }

    nonisolated private static func storedSelectedToken() -> SavedToken? {
        let tokens = storedTokens()
        let selectedId = SharedAccountStore.defaults.string(forKey: selectedTokenKey).flatMap(UUID.init(uuidString:))
        return tokens.first { $0.id == selectedId } ?? tokens.first
    }

    private static func migrateLegacyToken() {
        guard storedTokens().isEmpty, let token = KeychainStore.read(legacyTokenKey) else { return }
        let savedToken = SavedToken(id: UUID(), name: String(localized: .accountsDefaultName))
        guard KeychainStore.save(token, for: savedToken.keychainKey) else { return }
        if let data = try? JSONEncoder().encode([savedToken]) {
            SharedAccountStore.defaults.set(data, forKey: savedTokensKey)
            SharedAccountStore.defaults.set(savedToken.id.uuidString, forKey: selectedTokenKey)
        }
        KeychainStore.delete(legacyTokenKey)
    }

    private static func accountList(for tokenId: UUID) -> CachedResource<[Account]> {
        CachedResource(key: "accounts-\(tokenId.uuidString)")
    }

    var isSignedIn: Bool {
        client != nil
    }

    var isDemo: Bool {
        client?.isDemo ?? false
    }

    var accounts: CachedResource<[Account]> {
        if isDemo { return demoAccounts }
        guard let selectedTokenId, let list = accountLists[selectedTokenId] else { return emptyAccounts }
        return list
    }

    var selectedAccount: Account? {
        if isDemo { return accounts.value?.first }
        return accounts.value?.first { $0.id == selectedAccountId } ?? accounts.value?.first
    }

    func signIn(token: String) async throws {
        try await addToken(name: "", token: token)
    }

    func addToken(name: String, token: String) async throws {
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = CloudflareClient(token: trimmedToken)
        let fetchedAccounts = try await candidate.accountsForSignIn()
        var resolvedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if resolvedName.isEmpty {
            let profileName = try? await candidate.userProfile().displayName
            resolvedName = profileName ?? fetchedAccounts.first?.name ?? String(localized: .accountsDefaultName)
        }
        let savedToken = SavedToken(id: UUID(), name: resolvedName)
        guard KeychainStore.save(trimmedToken, for: savedToken.keychainKey) else {
            throw TokenStorageError.saveFailed
        }
        savedTokens.append(savedToken)
        persistTokens()
        SharedAccountStore.storeAccountIDs(fetchedAccounts.map(\.id), for: savedToken.id)
        let list = Self.accountList(for: savedToken.id)
        accountLists[savedToken.id] = list
        await list.refresh { fetchedAccounts }
        if selectedTokenId == nil || client == nil {
            select(tokenId: savedToken.id, accountId: fetchedAccounts.first?.id)
        }
    }

    func select(tokenId: UUID, accountId: String?) {
        guard !isDemo else { return }
        guard let savedToken = savedTokens.first(where: { $0.id == tokenId }),
              let token = KeychainStore.read(savedToken.keychainKey) else { return }
        if selectedTokenId != tokenId || client == nil {
            selectedTokenId = tokenId
            SharedAccountStore.defaults.set(tokenId.uuidString, forKey: Self.selectedTokenKey)
            client = CloudflareClient(token: token)
        }
        selectedAccountId = accountId ?? accountLists[tokenId]?.value?.first?.id
    }

    func selectAccount(id accountId: String) {
        guard !isDemo else { return }
        let owner = savedTokens.first { accountLists[$0.id]?.value?.contains { $0.id == accountId } == true }
        select(tokenId: owner?.id ?? selectedTokenId ?? UUID(), accountId: accountId)
    }

    func rename(tokenId: UUID, to name: String) async {
        guard let savedToken = savedTokens.first(where: { $0.id == tokenId }) else { return }
        var resolvedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if resolvedName.isEmpty {
            let profileName: String?
            if let token = KeychainStore.read(savedToken.keychainKey) {
                profileName = try? await CloudflareClient(token: token).userProfile().displayName
            } else {
                profileName = nil
            }
            resolvedName = profileName ?? accountLists[tokenId]?.value?.first?.name
                ?? String(localized: .accountsDefaultName)
        }
        guard let index = savedTokens.firstIndex(where: { $0.id == tokenId }) else { return }
        savedTokens[index].name = resolvedName
        persistTokens()
    }

    func delete(tokenId: UUID) {
        guard let savedToken = savedTokens.first(where: { $0.id == tokenId }) else { return }
        KeychainStore.delete(savedToken.keychainKey)
        savedTokens.removeAll { $0.id == tokenId }
        accountLists[tokenId] = nil
        DiskCache.shared.remove(for: "accounts-\(tokenId.uuidString)")
        persistTokens()
        SharedAccountStore.removeResources(for: tokenId)
        Task { await ResourceSearchIndex.rebuild() }
        WidgetCenter.shared.reloadAllTimelines()
        ControlCenter.shared.reloadAllControls()
        guard selectedTokenId == tokenId else { return }
        if let next = savedTokens.first {
            select(tokenId: next.id, accountId: nil)
        } else {
            signOut()
        }
    }

    func startDemo() async {
        DiskCache.shared.clear()
        SharedAccountStore.clearResources()
        Task { await ResourceSearchIndex.rebuild() }
        WidgetCenter.shared.reloadAllTimelines()
        ControlCenter.shared.reloadAllControls()
        demoAccounts = CachedResource(key: "accounts-demo")
        let demoClient = CloudflareClient.demo()
        SharedAccountStore.defaults.set(true, forKey: Self.demoModeKey)
        client = demoClient
        await demoAccounts.refresh { try await demoClient.accounts() }
        selectedAccountId = demoAccounts.value?.first?.id
    }

    func refreshAccounts() async {
        if isDemo, let client {
            await demoAccounts.refresh { try await client.accounts() }
        } else {
            for savedToken in savedTokens {
                guard let token = KeychainStore.read(savedToken.keychainKey),
                      let list = accountLists[savedToken.id] else { continue }
                let tokenClient = CloudflareClient(token: token)
                await list.refresh { try await tokenClient.accounts() }
                if let accounts = list.value {
                    SharedAccountStore.storeAccountIDs(accounts.map(\.id), for: savedToken.id)
                }
            }
        }
        if selectedAccount?.id != selectedAccountId {
            selectedAccountId = selectedAccount?.id
        }
    }

    func signOut() {
        SharedAccountStore.defaults.set(false, forKey: Self.demoModeKey)
        for savedToken in savedTokens {
            KeychainStore.delete(savedToken.keychainKey)
        }
        KeychainStore.delete(Self.legacyTokenKey)
        savedTokens = []
        accountLists = [:]
        persistTokens()
        selectedTokenId = nil
        SharedAccountStore.defaults.removeObject(forKey: Self.selectedTokenKey)
        client = nil
        selectedAccountId = nil
        DiskCache.shared.clear()
        SharedAccountStore.clearResources()
        Task { await ResourceSearchIndex.rebuild() }
        WidgetCenter.shared.reloadAllTimelines()
        ControlCenter.shared.reloadAllControls()
        demoAccounts = CachedResource(key: "accounts-demo")
    }

    private func persistTokens() {
        if let data = try? JSONEncoder().encode(savedTokens) {
            SharedAccountStore.defaults.set(data, forKey: Self.savedTokensKey)
        }
    }
}
