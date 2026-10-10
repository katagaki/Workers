import SwiftUI

struct SplitColumnModifier: ViewModifier {
    let horizontalSizeClass: UserInterfaceSizeClass?
    let isPlainWhenCompact: Bool

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 440)
                // The tab bar already offers a sidebar toggle on iPad.
                .toolbar(removing: .sidebarToggle)
        } else if isPlainWhenCompact {
            content
                .listStyle(.plain)
        } else {
            content
        }
    }
}

extension View {
    /// Columns inside a split view always report a compact size class, so the
    /// size class has to be read outside the split view and passed in.
    func splitColumn(_ horizontalSizeClass: UserInterfaceSizeClass?, isPlainWhenCompact: Bool = true) -> some View {
        modifier(SplitColumnModifier(horizontalSizeClass: horizontalSizeClass, isPlainWhenCompact: isPlainWhenCompact))
    }
}
