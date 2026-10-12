import SwiftUI

struct WorkerWidgetTitleBar: View {
    let title: Text

    init(name: String) {
        title = Text(verbatim: name)
    }

    init(_ title: LocalizedStringResource) {
        self.title = Text(title)
    }

    var body: some View {
        title
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color("AccentColor").gradient)
            .fixedSize(horizontal: false, vertical: true)
    }
}
