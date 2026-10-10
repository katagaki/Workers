import CloudflareKit
import SwiftUI

struct WorkerBindingsView: View {
    let settings: CachedResource<WorkerSettings>

    private var groupedBindings: [(String, [WorkerBinding])] {
        let bindings = settings.value?.bindings ?? []
        return Dictionary(grouping: bindings, by: \.typeTitle)
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        List {
            ForEach(groupedBindings, id: \.0) { title, bindings in
                Section(title) {
                    ForEach(bindings, id: \.bindingIdentifier) { binding in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(binding.name)
                                .font(.body.weight(.medium))
                            if let detail = binding.detail {
                                Text(detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                }
            }
            if let flags = settings.value?.compatibilityFlags, !flags.isEmpty {
                Section(.workersBindingsCompatibilityFlags) {
                    ForEach(flags, id: \.self) { flag in
                        Text(flag)
                    }
                }
            }
        }
        .navigationTitle(.workersBindingsTitle)
        .resourceStatus(
            settings,
            emptyTitle: .workersBindingsEmpty,
            emptySystemImage: "link",
            isEmpty: { ($0.bindings ?? []).isEmpty && ($0.compatibilityFlags ?? []).isEmpty }
        )
    }
}
