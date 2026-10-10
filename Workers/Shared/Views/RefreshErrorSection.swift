import SwiftUI

struct RefreshErrorSection<Value: Codable>: View {
    let resource: CachedResource<Value>

    var body: some View {
        if let error = resource.error, resource.value != nil {
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.sharedShowingSavedData)
                        Text(error.localizedDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
