import SwiftUI

struct AnalyticsSectionStatus<Value: Codable>: View {
    let resource: CachedResource<Value>

    var body: some View {
        if resource.value == nil {
            if let error = resource.error {
                Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            }
        }
    }
}
