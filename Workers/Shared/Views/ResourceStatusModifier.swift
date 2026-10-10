import SwiftUI

struct ResourceStatusModifier<Value: Codable>: ViewModifier {
    let resource: CachedResource<Value>
    let isEmpty: (Value) -> Bool
    let emptyTitle: LocalizedStringResource
    let emptySystemImage: String
    let emptyDescription: LocalizedStringResource?

    func body(content: Content) -> some View {
        content
            .overlay {
                if resource.isLoading && resource.value == nil {
                    ProgressView()
                } else if let error = resource.error,
                          resource.value.map(isEmpty) ?? true,
                          !resource.isLoading {
                    ContentUnavailableView {
                        Label(.sharedCouldntLoad, systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error.localizedDescription)
                    }
                } else if let value = resource.value, isEmpty(value) && !resource.isLoading {
                    ContentUnavailableView {
                        Label(emptyTitle, systemImage: emptySystemImage)
                    } description: {
                        if let emptyDescription {
                            Text(emptyDescription)
                        }
                    }
                }
            }
            .toolbar {
                if resource.isLoading && resource.value != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                    }
                }
            }
    }
}
