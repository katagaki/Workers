import CloudflareKit
import SwiftUI

struct AccountSwitcherMenu: View {
    @Environment(CloudflareSession.self) private var session
    @Binding var isManagingAccounts: Bool
    @Binding var isShowingDemoAlert: Bool

    var body: some View {
        Menu {
            if session.isDemo {
                Section {
                    ForEach(session.accounts.value ?? []) { account in
                        accountButton(account) {
                            session.selectAccount(id: account.id)
                        }
                    }
                }
            } else {
                ForEach(session.savedTokens) { savedToken in
                    Section(savedToken.name) {
                        ForEach(session.accountLists[savedToken.id]?.value ?? []) { account in
                            accountButton(account, tokenId: savedToken.id) {
                                session.select(tokenId: savedToken.id, accountId: account.id)
                            }
                        }
                    }
                }
            }
            Section {
                Button(.accountsManage) {
                    if session.isDemo {
                        isShowingDemoAlert = true
                    } else {
                        isManagingAccounts = true
                    }
                }
            }
        } label: {
            Label(.accountsSwitch, systemImage: "person.crop.circle")
        }
    }

    private func accountButton(_ account: Account, tokenId: UUID? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            let isSelected = account.id == session.selectedAccount?.id
                && (tokenId == nil || tokenId == session.selectedTokenId)
            if isSelected {
                Label(account.name, systemImage: "checkmark")
            } else {
                Text(account.name)
            }
        }
    }
}
