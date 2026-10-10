import CloudflareKit
import SwiftUI

struct DeploymentRow: View {
    let deployment: WorkerDeployment
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .accessibilityLabel(Text(.sharedActive))
                }
                Text(deployment.annotations?.message ?? sourceDescription)
                    .font(.body.weight(.medium))
                    .lineLimit(2)
                Spacer()
                Text(deployment.createdOn.relativeFormatted)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let authorEmail = deployment.authorEmail {
                Label(authorEmail, systemImage: "person.fill")
                    .labelStyle(.compact)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(deployment.versions, id: \.versionId) { version in
                Label {
                    Text(.workersDeploymentsVersionShare(version.percentage.formatted(), String(version.versionId.prefix(8))))
                } icon: {
                    Image(systemName: "square.stack.3d.up.fill")
                }
                .labelStyle(.compact)
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button {
                UIPasteboard.general.string = deployment.id
            } label: {
                Label(.workersDeploymentsCopyID, systemImage: "doc.on.doc")
            }
        }
    }

    private var sourceDescription: String {
        switch deployment.source {
        case "wrangler": String(localized: .workersDeploymentsSourceWrangler)
        case "api": String(localized: .workersDeploymentsSourceApi)
        case "dash": String(localized: .workersDeploymentsSourceDashboard)
        case "terraform": String(localized: .workersDeploymentsSourceTerraform)
        case let source?: String(localized: .workersDeploymentsSourceOther(source))
        case nil: String(localized: .workersDeploymentsSourceUnknown)
        }
    }
}
