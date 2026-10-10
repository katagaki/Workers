import SwiftUI

struct SettingsLabel: View {
    let title: LocalizedStringResource
    let glyph: SettingsIcon.Glyph
    let color: Color
    var titleColor: Color = .primary

    init(title: LocalizedStringResource, systemImage: String, color: Color, titleColor: Color = .primary) {
        self.title = title
        self.glyph = .system(systemImage)
        self.color = color
        self.titleColor = titleColor
    }

    init(title: LocalizedStringResource, image: ImageResource, color: Color, titleColor: Color = .primary) {
        self.title = title
        self.glyph = .asset(image)
        self.color = color
        self.titleColor = titleColor
    }

    var body: some View {
        Label {
            Text(title)
                .foregroundStyle(titleColor)
        } icon: {
            SettingsIcon(glyph: glyph, color: color)
        }
    }
}
