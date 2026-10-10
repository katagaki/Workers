import CloudflareKit
import SwiftUI

struct SavedTokenRow: View {
    let savedToken: SavedToken
    let accounts: [Account]
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(savedToken.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if !accounts.isEmpty {
                    Text(accounts.map(\.name).formatted(.list(type: .and)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
                    .fontWeight(.semibold)
            }
        }
    }
}
