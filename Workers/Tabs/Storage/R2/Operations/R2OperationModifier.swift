import SwiftUI

struct R2OperationModifier: ViewModifier {
    let runner: R2OperationRunner

    func body(content: Content) -> some View {
        content
            .disabled(runner.isRunning)
            .navigationBarBackButtonHidden(runner.isRunning)
            .overlay {
                if let title = runner.title {
                    progressCard(title: title)
                }
            }
            .alert(Text(.storageR2Failed), isPresented: Binding(
                get: { runner.failureMessage != nil },
                set: { if !$0 { runner.failureMessage = nil } }
            )) {
                Button(.sharedOk, role: .cancel) {}
            } message: {
                Text(runner.failureMessage ?? "")
            }
    }

    private func progressCard(title: LocalizedStringResource) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
            if runner.totalCount > 1 {
                ProgressView(value: Double(runner.completedCount), total: Double(runner.totalCount))
                Text(.storageR2ProgressCount(runner.completedCount + 1, runner.totalCount))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
            Button(.sharedCancel) {
                runner.cancel()
            }
        }
        .padding(20)
        .frame(maxWidth: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }
}

extension View {
    func r2Operation(_ runner: R2OperationRunner) -> some View {
        modifier(R2OperationModifier(runner: runner))
    }
}
