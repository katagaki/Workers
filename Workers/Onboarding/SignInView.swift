import SwiftUI

struct SignInView: View {
    @Environment(CloudflareSession.self) private var session
    @State private var token = ""
    @State private var isSigningIn = false
    @State private var errorMessage: String?
    @State private var isShowingError = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 12) {
                        ZStack {
                            Image("SignInCloud")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.tint)
                            SwingingHammer()
                        }
                        .frame(width: 128, height: 128)
                        .accessibilityHidden(true)
                        Text(.signInWelcomeMessage)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init())
                }
                .listSectionSpacing(.zero)

                Section {
                    Link(destination: TokenTemplate.url) {
                        HStack {
                            Spacer()
                            Text(.signInGettingTokenCreateToken)
                            Spacer()
                        }
                    }
                }

                Section {
                    SecureField(.signInTokenPlaceholder, text: $token)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.go)
                        .onSubmit(signIn)
                } header: {
                    Text(.signInTokenHeader)
                } footer: {
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    } else {
                        Text(.signInTokenFooter)
                    }
                }

                Section {
                    Button(action: signIn) {
                        HStack {
                            Spacer()
                            if isSigningIn {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(.signInTitle)
                            Spacer()
                        }
                    }
                    .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSigningIn)
                }

                Section {
                    Button {
                        Task { await session.startDemo() }
                    } label: {
                        HStack {
                            Spacer()
                            Text(.signInDemoTitle)
                            Spacer()
                        }
                    }
                } footer: {
                    Text(.signInDemoFooter)
                }
            }
            .alert(.signInErrorTitle, isPresented: $isShowingError) {
                Button(role: .confirm) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .navigationTitle(.signInWelcomeTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func signIn() {
        guard !isSigningIn else { return }
        isSigningIn = true
        errorMessage = nil
        Task {
            do {
                try await session.signIn(token: token)
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
            isSigningIn = false
        }
    }
}
