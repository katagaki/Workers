import CloudflareKit
import SwiftUI

struct MainTabView: View {
    @Environment(CloudflareSession.self) var session
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @SceneStorage("SelectedTab") var selectedTab: AppTab = .workers
    @State var resources: AccountResources?
    private let navigator = AppNavigator.shared

    var usesSidebar: Bool {
        horizontalSizeClass == .regular
    }

    var accountKey: String {
        "\(session.isDemo)-\(session.selectedTokenId?.uuidString ?? "")-\(session.selectedAccount?.id ?? "")"
    }

    var body: some View {
        TabView(selection: displayedSelection) {
            if usesSidebar {
                workersSection
                storageSection
                domainsSection
            } else {
                Tab(.tabsWorkers, systemImage: "hammer", value: AppTab.workers) {
                    accountScoped { resources in
                        WorkersListView(resources: resources)
                    }
                }
                Tab(.tabsStorage, systemImage: "externaldrive", value: AppTab.storage) {
                    accountScoped { resources in
                        StorageView(resources: resources)
                    }
                }
                Tab(.tabsDomains, systemImage: "globe", value: AppTab.domains) {
                    accountScoped { resources in
                        ZonesListView(resources: resources)
                    }
                }
            }
            Tab(.tabsAnalytics, systemImage: "chart.xyaxis.line", value: AppTab.analytics) {
                accountScoped { resources in
                    AnalyticsView(client: resources.client, accountId: resources.accountId)
                }
            }
            Tab(.tabsMore, systemImage: "ellipsis", value: AppTab.more) {
                MoreView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .onChange(of: accountKey, initial: true) { oldKey, newKey in
            if let client = session.client, let account = session.selectedAccount {
                if resources?.accountId != account.id || resources?.client !== client {
                    resources = AccountResources(client: client, accountId: account.id)
                }
            } else {
                resources = nil
            }
            if oldKey != newKey {
                selectedTab = selectedTab.tabBarTab
            }
        }
        .task(id: "\(accountKey)-\(usesSidebar)") {
            guard usesSidebar else { return }
            await resources?.reloadAll()
        }
        .onChange(of: usesSidebar, initial: true) {
            if !usesSidebar {
                selectedTab = selectedTab.tabBarTab
            }
        }
        .onChange(of: navigator.pendingRequest, initial: true) { _, request in
            guard let request else { return }
            session.selectAccount(id: request.accountId)
            if usesSidebar {
                selectedTab = request.destination.sidebarTab
                navigator.pendingRequest = nil
            } else {
                selectedTab = request.destination.tab
            }
        }
        .demoModeAccessory(isEnabled: session.isDemo && !UserDefaults.standard.bool(forKey: "ScreenshotMode"))
    }

    /// On iPad the sidebar sections replace the Workers, Storage, and Domains tabs, so
    /// those land on the first item of their section instead.
    private var displayedSelection: Binding<AppTab> {
        Binding {
            usesSidebar ? sidebarSelection(for: selectedTab) : selectedTab
        } set: { tab in
            selectedTab = tab
        }
    }

    private func sidebarSelection(for tab: AppTab) -> AppTab {
        guard let resources else { return tab }
        switch tab {
        case .workers:
            return resources.sortedScripts.first.map { .worker(name: $0.name) } ?? .analytics
        case .storage:
            return .storageCategory(.d1)
        case .domains:
            return resources.sortedZones.first.map { .zone(id: $0.id) } ?? .analytics
        default:
            return tab
        }
    }

    @ViewBuilder
    func accountScoped(
        @ViewBuilder content: @escaping (AccountResources) -> some View
    ) -> some View {
        if let resources, resources.accountId == session.selectedAccount?.id {
            content(resources)
                .id(accountKey)
        } else if session.accounts.isLoading || session.selectedAccount != nil {
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
