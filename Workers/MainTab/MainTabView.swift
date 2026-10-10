import CloudflareKit
import SwiftUI

struct MainTabView: View {
    @Environment(CloudflareSession.self) var session
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @SceneStorage("SelectedTab") var selectedTab: AppTab = .workers
    @State var resources: AccountResources?
    @State private var recentSidebarPick: SidebarPick?
    @State private var isShowingAccount = false
    private let navigator = AppNavigator.shared

    var usesSidebar: Bool {
        horizontalSizeClass == .regular
    }

    var accountKey: String {
        "\(session.isDemo)-\(session.selectedTokenId?.uuidString ?? "")-\(session.selectedAccount?.id ?? "")"
    }

    var body: some View {
        TabView(selection: tabSelection) {
            if usesSidebar {
                workersSection
                storageSection
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
            }
            Tab(.tabsWorkersAI, systemImage: "brain", value: AppTab.workersAI) {
                accountScoped { resources in
                    WorkersAIView(resources: resources)
                }
            }
            if usesSidebar {
                domainsSection
            } else {
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
        }
        .tabViewStyle(.sidebarAdaptable)
        .environment(\.isAccountSheetPresented, $isShowingAccount)
        .sheet(isPresented: $isShowingAccount) {
            AccountView()
        }
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
        .onChange(of: sidebarLandingKey, initial: true) {
            guard usesSidebar else { return }
            let landing = sidebarSelection(for: selectedTab)
            if landing != selectedTab {
                selectedTab = landing
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

    /// Picking another item in the selected section from the portrait overlay sidebar makes
    /// the tab bar select the section's previous item again right away, so that revert is ignored.
    private var tabSelection: Binding<AppTab> {
        Binding {
            selectedTab
        } set: { tab in
            if usesSidebar, let pick = recentSidebarPick, tab == pick.previous,
               tab.tabBarTab == pick.picked.tabBarTab, Date.now.timeIntervalSince(pick.date) < 0.5 {
                return
            }
            recentSidebarPick = SidebarPick(previous: selectedTab, picked: tab, date: .now)
            selectedTab = tab
        }
    }

    /// Changes whenever the selection may need moving onto a sidebar item.
    private var sidebarLandingKey: String {
        "\(usesSidebar)-\(selectedTab.rawValue)-\(resources?.scripts.value?.count ?? -1)-\(resources?.zones.value?.count ?? -1)"
    }

    /// On iPad the sidebar sections replace the Workers, Storage, and Domains tabs, so
    /// those land on the first item of their section instead.
    private func sidebarSelection(for tab: AppTab) -> AppTab {
        guard let resources else { return tab }
        switch tab {
        case .workers:
            guard let scripts = resources.scripts.value else { return tab }
            return scripts.isEmpty ? .analytics : .worker(name: resources.sortedScripts[0].name)
        case .storage:
            return .storageCategory(.d1)
        case .domains:
            guard let zones = resources.zones.value else { return tab }
            return zones.isEmpty ? .analytics : .zone(id: resources.sortedZones[0].id)
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
            NavigationStack {
                ProgressView()
                    .accountToolbar()
            }
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
                .accountToolbar()
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
