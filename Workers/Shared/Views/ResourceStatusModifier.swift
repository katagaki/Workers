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
                if let value = resource.value {
                    if isEmpty(value) && !resource.isLoading {
                        ContentUnavailableView {
                            Label(emptyTitle, systemImage: emptySystemImage)
                        } description: {
                            if let emptyDescription {
                                Text(emptyDescription)
                            }
                        }
                    }
                } else if resource.isLoading {
                    ProgressView()
                } else if let error = resource.error {
                    ContentUnavailableView {
                        Label(.sharedCouldntLoad, systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error.localizedDescription)
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
