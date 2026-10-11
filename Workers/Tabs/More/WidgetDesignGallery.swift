import SwiftUI
import WidgetKit

struct WidgetDesignGallery: View {
    var body: some View {
        List {
            Section {
                Text(.widgetsSample).foregroundStyle(.secondary)
            }
            ForEach(WorkerWidgetDesign.allCases, id: \.self) { design in
                Section(design.title) {
                    WorkerWidgetView(snapshot: .sample, design: design)
                        .padding(16).frame(height: 170)
                        .background(.background, in: RoundedRectangle(cornerRadius: 22))
                        .accessibilityIdentifier("WidgetPreview.\(design.rawValue)")
                    HStack {
                        WorkerWidgetView(snapshot: .sample, design: design, family: .systemSmall)
                            .padding(16).frame(width: 158, height: 158)
                            .background(.background, in: RoundedRectangle(cornerRadius: 22))
                        Spacer()
                        WorkerWidgetView(snapshot: .sample, design: design, family: .accessoryRectangular)
                            .frame(width: 140)
                    }
                }.listRowBackground(Color(.secondarySystemGroupedBackground))
            }
        }
        .navigationTitle(.widgetsGallery)
        .navigationBarTitleDisplayMode(.inline)
    }
}
