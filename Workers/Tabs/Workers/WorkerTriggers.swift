import CloudflareKit
import SwiftUI

struct WorkerTriggers: Codable {
    let customDomains: [WorkerCustomDomain]
    let routes: [WorkerRoute]
    let schedules: [WorkerSchedule]

    var isEmpty: Bool {
        customDomains.isEmpty && routes.isEmpty && schedules.isEmpty
    }
}
