import SwiftUI

struct SettingsLabel: View {
    let title: LocalizedStringResource
    let systemImage: String
    let color: Color
    var titleColor: Color = .primary

    var body: some View {
        Label {
            Text(title)
                .foregroundStyle(titleColor)
        } icon: {
            SettingsIcon(systemImage: systemImage, color: color)
        }
    }
}
