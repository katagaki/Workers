import AppIntents

struct WorkersShortcuts: AppShortcutsProvider {
    // Phrases must be string literals for metadata extraction, so they are localized in AppShortcuts.xcstrings.
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetWorkerRequestsIntent(),
            phrases: [
                "Check worker requests in \(.applicationName)",
                "How many requests did my worker get in \(.applicationName)"
            ],
            shortTitle: "Intents.WorkerRequests.ShortTitle",
            systemImageName: "chart.xyaxis.line"
        )
        AppShortcut(
            intent: PurgeZoneCacheIntent(),
            phrases: ["Purge cache in \(.applicationName)"],
            shortTitle: "Intents.PurgeCache.ShortTitle",
            systemImageName: "arrow.clockwise"
        )
        AppShortcut(
            intent: SetZonePausedIntent(),
            phrases: ["Pause a domain in \(.applicationName)"],
            shortTitle: "Intents.SetPaused.ShortTitle",
            systemImageName: "pause.fill"
        )
        AppShortcut(
            intent: GetWorkerErrorRateIntent(),
            phrases: ["Check worker errors in \(.applicationName)"],
            shortTitle: "Intents.ErrorRate.Title",
            systemImageName: "exclamationmark.triangle"
        )
        AppShortcut(
            intent: RollbackWorkerIntent(),
            phrases: ["Roll back a worker in \(.applicationName)"],
            shortTitle: "Intents.Rollback.Title",
            systemImageName: "arrow.uturn.backward"
        )
        AppShortcut(
            intent: OpenWorkerIntent(),
            phrases: ["Open a worker in \(.applicationName)"],
            shortTitle: "Intents.OpenWorker.ShortTitle",
            systemImageName: "hammer"
        )
        AppShortcut(
            intent: OpenZoneIntent(),
            phrases: ["Open a domain in \(.applicationName)"],
            shortTitle: "Intents.OpenZone.ShortTitle",
            systemImageName: "globe"
        )
    }
}
