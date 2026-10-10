import CloudflareKit
import SwiftUI

struct MoreView: View {
    @Environment(CloudflareSession.self) private var session
    @State private var isConfirmingSignOut = false
    @State private var isConfirmingClearCache = false

    var body: some View {
        @Bindable var session = session
        NavigationStack {
            List {
                if let accounts = session.accounts.value, !accounts.isEmpty {
                    Section(.moreAccount) {
                        Picker(.moreAccount, selection: Binding(
                            get: { session.selectedAccount?.id ?? "" },
                            set: { session.selectedAccountId = $0 }
                        )) {
                            ForEach(accounts) { account in
                                Text(account.name).tag(account.id)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
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
            .navigationTitle(.tabsMore)
            .refreshable {
                await session.refreshAccounts()
            }
            .alert(Text(.moreClearCacheConfirm), isPresented: $isConfirmingClearCache) {
                Button(.sharedCancel, role: .cancel) {}
                Button(.moreClearCacheTitle, role: .destructive) {
                    DiskCache.shared.clear()
                }
            }
            .alert(
                Text(session.isDemo ? .moreExitDemoConfirm : .moreSignOutConfirm),
                isPresented: $isConfirmingSignOut
            ) {
                Button(.sharedCancel, role: .cancel) {}
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
