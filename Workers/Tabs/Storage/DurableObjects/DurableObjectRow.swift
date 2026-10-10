import CloudflareKit
import SwiftUI

struct DurableObjectRow: View {
    let object: DurableObjectInstance

    var body: some View {
        Label {
            Text(object.id)
                .font(.subheadline)
                .lineLimit(1)
                .truncationMode(.middle)
        } icon: {
            Image(systemName: object.hasStoredData == true ? "cylinder.split.1x2.fill" : "cylinder.split.1x2")
                .foregroundStyle(.orange)
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = object.id
            } label: {
                Label(.durableObjectsObjectsCopyID, systemImage: "doc.on.doc")
            }
        }
    }
}
