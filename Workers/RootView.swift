import CoreSpotlight
import SwiftUI

struct RootView: View {
    @Environment(CloudflareSession.self) private var session
    @State private var resourceError: String?

    var body: some View {
        Group {
            if session.isSignedIn {
                MainTabView()
                    .task {
                        await session.refreshAccounts()
                        await ResourceSearchIndex.rebuild()
                    }
            } else {
                SignInView()
            }
        }
        .onOpenURL { url in
            guard let worker = ResourceLinkRouter.worker(from: url) else { return }
            Task {
                do { try await ResourceLinkRouter.open(worker: worker) }
                catch { resourceError = error.localizedDescription }
            }
        }
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else { return }
            Task {
                do { try await ResourceLinkRouter.openSpotlight(identifier: identifier) }
                catch { resourceError = error.localizedDescription }
            }
        }
        .alert(Text(.navigationOpenFailed), isPresented: Binding(get: { resourceError != nil }, set: { if !$0 { resourceError = nil } })) {
            Button(.sharedOk, role: .cancel) { resourceError = nil }
        } message: {
            Text(verbatim: resourceError ?? "")
        }
    }
}
