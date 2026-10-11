import AppIntents

struct ZoneControlConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Controls.Zone"
    @Parameter(title: "Intents.Zone.Type") var zone: ZoneEntity?
}
