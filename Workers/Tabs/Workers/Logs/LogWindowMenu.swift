import SwiftUI

struct LogWindowMenu: View {
    @Binding var window: LogWindow

    var body: some View {
        Menu {
            Picker(.sharedTimeRange, selection: $window) {
                ForEach(LogWindow.allCases) { window in
                    Text(window.title).tag(window)
                }
            }
        } label: {
            Label(.sharedTimeRange, systemImage: "calendar")
        }
    }
}
