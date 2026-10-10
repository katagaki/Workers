import SwiftUI

struct RootView: View {
    @Environment(CloudflareSession.self) private var session

    var body: some View {
        @Bindable var session = session
        if session.isSignedIn {
            MainTabView()
                .task {
                    await session.refreshAccounts()
                }
                .alert(Text(.signInSaveFailedTitle), isPresented: $session.isTokenSaveFailed) {
                    Button(role: .confirm) {}
                } message: {
                    Text(.signInSaveFailedMessage)
                }
        } else {
            SignInView()
        }
    }
}
