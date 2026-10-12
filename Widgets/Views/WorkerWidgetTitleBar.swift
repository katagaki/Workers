import SwiftUI

struct WorkerWidgetTitleBar: View {
    let name: String

    var body: some View {
        Text(verbatim: name)
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
