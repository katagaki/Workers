import CloudflareKit
import SwiftUI

struct MainTabView: View {
    @Environment(CloudflareSession.self) private var session
    @SceneStorage("SelectedTab") private var selectedTab: AppTab = .workers
    private let navigator = AppNavigator.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(.tabsWorkers, systemImage: "hammer", value: AppTab.workers) {
                accountScoped { client, accountId in
                    WorkersListView(client: client, accountId: accountId)
                }
            }
            Tab(.tabsStorage, systemImage: "externaldrive", value: AppTab.storage) {
                accountScoped { client, accountId in
                    StorageView(client: client, accountId: accountId)
                }
            }
            Tab(.tabsDomains, systemImage: "globe", value: AppTab.domains) {
                accountScoped { client, accountId in
                    ZonesListView(client: client, accountId: accountId)
                }
            }
            Tab(.tabsAnalytics, systemImage: "chart.xyaxis.line", value: AppTab.analytics) {
                accountScoped { client, accountId in
                    AnalyticsView(client: client, accountId: accountId)
                }
            }
            Tab(.tabsMore, systemImage: "ellipsis", value: AppTab.more) {
                MoreView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .onChange(of: navigator.pendingRequest, initial: true) { _, request in
            guard let request else { return }
            session.selectedAccountId = request.accountId
            selectedTab = request.destination.tab
        }
        .demoModeAccessory(isEnabled: session.isDemo)
    }

    @ViewBuilder
    private func accountScoped(
        @ViewBuilder content: @escaping (CloudflareClient, String) -> some View
    ) -> some View {
        if let client = session.client, let account = session.selectedAccount {
            content(client, account.id)
                .id(account.id)
        } else if session.accounts.isLoading {
            ProgressView()
        } else {
            NavigationStack {
                ContentUnavailableView {
                    Label(.accountNoAccountTitle, systemImage: "person.crop.circle.badge.questionmark")
                } description: {
                    Text(session.accounts.error?.localizedDescription
                         ?? String(localized: .accountNoAccountMessage))
                } actions: {
                    Button(.accountTryAgain) {
                        Task { await session.refreshAccounts() }
                    }
                }
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func demoModeAccessory(isEnabled: Bool) -> some View {
        if #available(iOS 26.1, *) {
            tabViewBottomAccessory(isEnabled: isEnabled) {
                DemoModeBanner()
            }
        } else if isEnabled {
            tabViewBottomAccessory {
                DemoModeBanner()
            }
        } else {
            self
        }
    }
}
