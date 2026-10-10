import SwiftUI

struct DemoModeBanner: View {
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        VStack(spacing: 0) {
            Text(.sharedDemoModeTitle)
                .font(.subheadline.weight(.semibold))
            if placement != .inline {
                Text(.sharedDemoModeMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.red.opacity(0.15))
        .accessibilityElement(children: .combine)
    }
}
