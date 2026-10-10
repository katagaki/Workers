import SwiftUI

extension View {
    func resourceStatus<Value: Codable>(
        _ resource: CachedResource<Value>,
        emptyTitle: LocalizedStringResource,
        emptySystemImage: String,
        emptyDescription: LocalizedStringResource? = nil,
        isEmpty: @escaping (Value) -> Bool
    ) -> some View {
        modifier(ResourceStatusModifier(
            resource: resource,
            isEmpty: isEmpty,
            emptyTitle: emptyTitle,
            emptySystemImage: emptySystemImage,
            emptyDescription: emptyDescription
        ))
    }

    func resourceStatus<Element: Codable>(
        _ resource: CachedResource<[Element]>,
        emptyTitle: LocalizedStringResource,
        emptySystemImage: String,
        emptyDescription: LocalizedStringResource? = nil
    ) -> some View {
        resourceStatus(
            resource,
            emptyTitle: emptyTitle,
            emptySystemImage: emptySystemImage,
            emptyDescription: emptyDescription,
            isEmpty: \.isEmpty
        )
    }
}
