import SwiftUI

struct RootView: View {
    @Environment(CloudflareSession.self) private var session

    var body: some View {
        if session.isSignedIn {
            MainTabView()
                .task {
                    await session.refreshAccounts()
                }
        } else {
            SignInView()
        }
    }
}
