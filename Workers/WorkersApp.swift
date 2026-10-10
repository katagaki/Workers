import SwiftUI

@main
struct WorkersApp: App {
    @State private var session = CloudflareSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
    }
}
