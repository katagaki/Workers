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
                    NavigationLink(design.title) { WidgetDesignDetailView(design: design) }
                        .accessibilityIdentifier("WidgetDetail.\(design.rawValue)")
                }.listRowBackground(Color(.secondarySystemGroupedBackground))
            }
        }
        .navigationTitle(.widgetsGallery)
        .navigationBarTitleDisplayMode(.inline)
    }
}
