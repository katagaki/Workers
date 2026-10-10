import SwiftUI

extension EnvironmentValues {
    @Entry var isAccountSheetPresented: Binding<Bool> = .constant(false)
}

private struct AccountToolbarModifier: ViewModifier {
    @Environment(\.isAccountSheetPresented) private var isPresented

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresented.wrappedValue = true
                } label: {
                    Label(.accountTitle, systemImage: "person.crop.circle")
                }
            }
        }
    }
}

extension View {
    func accountToolbar() -> some View {
        modifier(AccountToolbarModifier())
    }
}
