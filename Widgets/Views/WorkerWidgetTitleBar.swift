import SwiftUI
import WidgetKit

struct WorkerWidgetTitleBar: View {
    let title: Text
    @Environment(\.widgetRenderingMode) private var renderingMode

    init(name: String) {
        title = Text(verbatim: name)
    }

    init(_ title: LocalizedStringResource) {
        self.title = Text(title)
    }

    var body: some View {
        if renderingMode == .fullColor {
            label
                .foregroundStyle(.white)
                .background(Color("AccentColor").gradient)
        } else {
            label.widgetAccentable()
        }
    }

    private var label: some View {
        title
            .font(.subheadline.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .fixedSize(horizontal: false, vertical: true)
    }
}
