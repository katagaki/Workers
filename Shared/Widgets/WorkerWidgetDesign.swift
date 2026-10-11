import AppIntents

nonisolated enum WorkerWidgetDesign: String, AppEnum, CaseIterable {
    case traffic, reliability, trend, overview, compact

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Widgets.Design")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .traffic: "Widgets.Design.Traffic", .reliability: "Widgets.Design.Reliability",
        .trend: "Widgets.Design.Trend", .overview: "Widgets.Design.Overview", .compact: "Widgets.Design.Compact"
    ]

    var title: LocalizedStringResource {
        switch self {
        case .traffic: .widgetsDesignTraffic
        case .reliability: .widgetsDesignReliability
        case .trend: .widgetsDesignTrend
        case .overview: .widgetsDesignOverview
        case .compact: .widgetsDesignCompact
        }
    }
}

struct WorkerWidgetConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Widgets.Configuration"
    @Parameter(title: "Intents.Worker.Type") var worker: WorkerEntity?
    @Parameter(title: "Widgets.Design", default: .traffic) var design: WorkerWidgetDesign
}
