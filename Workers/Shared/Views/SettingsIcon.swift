import SwiftUI

struct SettingsIcon: View {
    let systemImage: String
    let color: Color

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 30

    private var glyphPointSize: CGFloat {
        let referencePointSize: CGFloat = 100
        let configuration = UIImage.SymbolConfiguration(pointSize: referencePointSize, weight: .semibold)
        guard let symbol = UIImage(systemName: systemImage, withConfiguration: configuration),
              symbol.size.width > 0, symbol.size.height > 0 else {
            return size * 0.5
        }
        let fittingScale = min(size * 0.66 / symbol.size.width, size * 0.54 / symbol.size.height)
        return referencePointSize * fittingScale
    }

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: glyphPointSize, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient, in: .rect(cornerRadius: size * 0.24, style: .continuous))
            .accessibilityHidden(true)
    }
}
