import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: BJSpacing.l) {
                header
                    .padding(.top, BJSpacing.xl)
                VStack(spacing: BJSpacing.m) {
                    FormTextField(label: "E-mail", text: $viewModel.loginEmail, keyboard: .emailAddress)
                    FormTextField(label: "Hasło", text: $viewModel.loginPassword, secure: true)
                }
                if let message = viewModel.errorMessage {
                    AuthErrorLabel(message: message)
                }
                PrimaryButton(title: "Zaloguj się", isLoading: viewModel.isLoading) {
                    Task { await viewModel.login() }
                }
                NavigationLink(value: AuthRoute.forgotPassword) {
                    Text("Nie pamiętam hasła")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.bjAccent)
                }
                .padding(.top, BJSpacing.s)
            }
            .padding(BJSpacing.l)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Logowanie")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.clearError() }
    }

    private var header: some View {
        AuthHeader(
            icon: "person.crop.circle.badge.checkmark",
            title: "Miło Cię znów widzieć",
            subtitle: "Zaloguj się, aby wrócić do zadań i nagród swojej rodziny."
        )
    }
}
