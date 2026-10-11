import SwiftUI

struct WorkerWidgetTitleBar: View {
    let name: String

    var body: some View {
        Text(verbatim: name)
            .font(.body)
            .foregroundStyle(Color("AccentColor"))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background {
                LinearGradient(
                    colors: [Color("AccentColor").opacity(0.25), Color("AccentColor").opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
    }
}
