import SwiftUI

struct AIModelRow: View {
    let modelId: String
    let requests: Int

    private var components: [String] { modelId.split(separator: "/").map(String.init) }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(components.last ?? modelId)
                    .foregroundStyle(.primary)
                if components.count > 1 {
                    Text(components[components.count - 2])
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(requests.compactFormatted)
                .foregroundStyle(.secondary)
                .fixedSize()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(modelId))
        .accessibilityValue(Text(.workersAIModelsRequests(requests.compactFormatted)))
    }
}
