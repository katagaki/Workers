import SwiftUI
import WidgetKit

struct WidgetDesignDetailView: View {
    let design: WorkerWidgetDesign

    var body: some View {
        List {
            Section(.widgetsHomeScreen) {
                WorkerWidgetView(snapshot: .sample, design: design)
                    .frame(height: 170)
                    .background(.background, in: RoundedRectangle(cornerRadius: 22))
                WorkerWidgetView(snapshot: .sample, design: design, family: .systemSmall)
                    .frame(width: 170, height: 170)
                    .background(.background, in: RoundedRectangle(cornerRadius: 22))
                    .frame(maxWidth: .infinity)
            }
            Section {
                HStack(spacing: 24) {
                    WorkerWidgetView(snapshot: .sample, design: design, family: .accessoryCircular)
                        .frame(width: 66, height: 66)
                    WorkerWidgetView(snapshot: .sample, design: design, family: .accessoryRectangular)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                WorkerWidgetView(snapshot: .sample, design: design, family: .accessoryInline)
                    .font(.caption).lineLimit(1)
            } header: {
                Text(.widgetsLockScreen)
            } footer: {
                Text(.widgetsSample)
            }
        }
        .navigationTitle(design.title)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("WidgetDesignDetail")
    }
}
