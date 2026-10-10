import SwiftUI

struct AccountSelectionSection: View {
    @Environment(CloudflareSession.self) private var session
    @Binding var isManagingAccounts: Bool
    @Binding var isShowingDemoAlert: Bool

    var body: some View {
        Section {
            if !session.isDemo {
                if session.savedTokens.count > 1 {
                    Picker(.accountsProfile, selection: profileSelection) {
                        ForEach(session.savedTokens) { savedToken in
                            Text(savedToken.name).tag(Optional(savedToken.id))
                        }
                    }
                } else if let savedToken = session.savedTokens.first {
                    LabeledContent(.accountsProfile, value: savedToken.name)
                }
            }

            if let accounts = session.accounts.value, accounts.count > 1 {
                Picker(.accountTitle, selection: accountSelection) {
                    ForEach(accounts) { account in
                        Text(account.name).tag(account.id)
                    }
                }
            } else if let account = session.selectedAccount {
                LabeledContent(.accountTitle, value: account.name)
            }

            Button(.accountsManage) {
                if session.isDemo {
                    isShowingDemoAlert = true
                } else {
                    isManagingAccounts = true
                }
            }
        }
    }

    private var profileSelection: Binding<UUID?> {
        Binding {
            session.selectedTokenId
        } set: { tokenId in
            guard let tokenId else { return }
            session.select(tokenId: tokenId, accountId: nil)
        }
    }

    private var accountSelection: Binding<String> {
        Binding {
            session.selectedAccount?.id ?? ""
        } set: { accountId in
            if session.isDemo {
                session.selectAccount(id: accountId)
            } else if let tokenId = session.selectedTokenId {
                session.select(tokenId: tokenId, accountId: accountId)
            }
        }
    }
}
