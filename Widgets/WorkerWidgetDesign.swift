import AppIntents

nonisolated enum WorkerWidgetDesign: String, AppEnum, CaseIterable {
    case traffic, reliability, trend, overview, compact

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Widgets.Design")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .traffic: "Widgets.Design.Traffic", .reliability: "Widgets.Design.Reliability",
        .trend: "Widgets.Design.Trend", .overview: "Widgets.Design.Overview", .compact: "Widgets.Design.Compact"
    ]
}

struct WorkerWidgetConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Widgets.Configuration"
    @Parameter(title: "Intents.Worker.Type") var worker: WorkerEntity?
    @Parameter(title: "Widgets.Design", default: .traffic) var design: WorkerWidgetDesign
}
