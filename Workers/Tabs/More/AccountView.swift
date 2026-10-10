import CloudflareKit
import SwiftUI

struct AccountView: View {
    @Environment(CloudflareSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingSignOut = false
    @State private var isConfirmingClearCache = false
    @State private var isManagingAccounts = false
    @State private var isShowingDemoAccountsAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AccountSwitcherMenu(
                        isManagingAccounts: $isManagingAccounts,
                        isShowingDemoAlert: $isShowingDemoAccountsAlert
                    )
                }

                if let client = session.client, let account = session.selectedAccount {
                    AccountUsageSection(
                        client: client,
                        account: account,
                        tokenName: session.savedTokens.first { $0.id == session.selectedTokenId }?.name
                    )
                    .id("\(session.selectedTokenId?.uuidString ?? "")-\(account.id)")
                }

                Section(.moreCloudflare) {
                    Link(destination: URL(string: "https://dash.cloudflare.com")!) {
                        safariLinkLabel(title: .moreDashboard, systemImage: "cloud.fill", color: .orange)
                    }
                    Link(destination: URL(string: "https://www.cloudflarestatus.com")!) {
                        safariLinkLabel(title: .moreSystemStatus, systemImage: "waveform.path.ecg", color: .green)
                    }
                }

                Section {
                    Button {
                        isConfirmingClearCache = true
                    } label: {
                        SettingsLabel(title: .moreClearCacheTitle, systemImage: "trash.fill", color: .gray)
                    }
                    Button(role: .destructive) {
                        isConfirmingSignOut = true
                    } label: {
                        SettingsLabel(
                            title: session.isDemo ? .moreExitDemoTitle : .moreSignOutTitle,
                            systemImage: "rectangle.portrait.and.arrow.right",
                            color: .red,
                            titleColor: .red
                        )
                    }
                } footer: {
                    Text(.moreClearCacheFooter)
                }

                Section {
                    Link(destination: URL(string: "https://github.com/katagaki/Workers")!) {
                        HStack {
                            SettingsLabel(title: .moreSourceCode, systemImage: "chevron.left.forwardslash.chevron.right", color: .gray)
                            Spacer()
                            Text(verbatim: "katagaki/Workers")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                }
            }
            .navigationTitle(.accountTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .confirm) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isManagingAccounts) {
                ManageAccountsView()
            }
            .alert(Text(.accountsDemoUnavailableTitle), isPresented: $isShowingDemoAccountsAlert) {
                Button(.sharedOk, role: .cancel) {}
            } message: {
                Text(.accountsDemoUnavailableMessage)
            }
            .refreshable {
                await session.refreshAccounts()
            }
            .alert(Text(.moreClearCacheConfirm), isPresented: $isConfirmingClearCache) {
                Button(role: .cancel) {}
                Button(.moreClearCacheTitle, role: .destructive) {
                    DiskCache.shared.clear()
                }
            }
            .alert(
                Text(session.isDemo ? .moreExitDemoConfirm : .moreSignOutConfirm),
                isPresented: $isConfirmingSignOut
            ) {
                Button(role: .cancel) {}
                Button(session.isDemo ? .moreExitDemoTitle : .moreSignOutTitle, role: .destructive) {
                    session.signOut()
                }
            } message: {
                if session.isDemo {
                    Text(.moreExitDemoMessage)
                } else {
                    Text(.moreSignOutMessage)
                }
            }
        }
    }

    private func safariLinkLabel(title: LocalizedStringResource, systemImage: String, color: Color) -> some View {
        HStack {
            SettingsLabel(title: title, systemImage: systemImage, color: color)
            Spacer()
            Image(systemName: "safari")
                .font(.body)
                .foregroundStyle(Color(.secondaryLabel))
        }
    }
}
