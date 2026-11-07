import CloudflareKit
import UIKit

final class WorkersAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        guard identifier == R2BackgroundUploader.sessionIdentifier else {
            completionHandler()
            return
        }
        R2UploadCenter.shared.backgroundEventsCompletion = completionHandler
    }
}
