import SwiftUI

@main
struct WorkersApp: App {
    @UIApplicationDelegateAdaptor(WorkersAppDelegate.self) private var appDelegate
    @State private var session = CloudflareSession()
    @State private var uploads = R2UploadCenter.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(uploads)
        }
    }
}
