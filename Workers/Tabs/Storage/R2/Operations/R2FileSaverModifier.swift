import CloudflareKit
import SwiftUI

struct R2FileSaverModifier: ViewModifier {
    @Binding var downloads: [R2DownloadedObject]
    let runner: R2OperationRunner

    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .fileMover(
                isPresented: $isPresented,
                files: downloads.map(\.fileURL),
                onCompletion: { result in
                    if case .failure(let error) = result {
                        runner.failureMessage = error.localizedDescription
                    }
                    finish()
                },
                onCancellation: finish
            )
            .onChange(of: downloads.isEmpty) { _, isEmpty in
                isPresented = !isEmpty
            }
    }

    private func finish() {
        downloads.forEach { $0.removeTemporaryFile() }
        downloads = []
    }
}

extension View {
    func r2FileSaver(downloads: Binding<[R2DownloadedObject]>, runner: R2OperationRunner) -> some View {
        modifier(R2FileSaverModifier(downloads: downloads, runner: runner))
    }
}
