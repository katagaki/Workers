import AppIntents
import CloudflareKit
import SwiftUI
import WidgetKit

struct WorkerMetricsEntry: TimelineEntry {
    let date: Date
    let configuration: WorkerWidgetConfiguration
    let snapshot: WorkerWidgetSnapshot?
    var stale = false
}

struct WorkerMetricsProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WorkerMetricsEntry {
        WorkerMetricsEntry(date: .now, configuration: WorkerWidgetConfiguration(), snapshot: .sample)
    }

    func snapshot(for configuration: WorkerWidgetConfiguration, in context: Context) async -> WorkerMetricsEntry {
        if context.isPreview { return WorkerMetricsEntry(date: .now, configuration: configuration, snapshot: .sample) }
        return await load(configuration)
    }

    func timeline(for configuration: WorkerWidgetConfiguration, in context: Context) async -> Timeline<WorkerMetricsEntry> {
        Timeline(entries: [await load(configuration)], policy: .after(.now.addingTimeInterval(900)))
    }

    private func load(_ configuration: WorkerWidgetConfiguration) async -> WorkerMetricsEntry {
        guard let worker = configuration.worker else {
            return WorkerMetricsEntry(date: .now, configuration: configuration, snapshot: nil)
        }
        let cached = SharedAccountStore.value(key: "Widget.\(worker.id)", as: WorkerWidgetSnapshot.self)
        do {
            let points = try await IntentContext.client(accountId: worker.accountId).workerAnalytics(accountId: worker.accountId, range: .day, scriptName: worker.name)
            let snapshot = WorkerWidgetSnapshot(worker: worker, analytics: points)
            SharedAccountStore.store(snapshot, key: snapshot.cacheKey)
            return WorkerMetricsEntry(date: .now, configuration: configuration, snapshot: snapshot)
        } catch {
            let authorized = SharedAccountStore.accountIDs.contains(worker.accountId)
            return WorkerMetricsEntry(date: .now, configuration: configuration, snapshot: authorized ? cached : nil, stale: true)
        }
    }
}

struct WorkerMetricsWidget: Widget {
    let kind = "WorkerMetrics"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WorkerWidgetConfiguration.self, provider: WorkerMetricsProvider()) { entry in
            WorkerMetricsEntryView(entry: entry).widgetURL(entry.snapshot?.url).containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(.widgetsConfiguration)
        .description(.widgetsDescription)
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

struct WorkerMetricsEntryView: View {
    let entry: WorkerMetricsEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        if let snapshot = entry.snapshot {
            VStack(alignment: .leading, spacing: 2) {
                WorkerWidgetView(snapshot: snapshot, design: entry.configuration.design, family: family)
                if entry.stale { Text(.widgetsStale).font(.body).foregroundStyle(.secondary) }
            }
        } else {
            WorkerWidgetEmptyView(needsConfiguration: entry.configuration.worker == nil, family: family)
        }
    }
}
