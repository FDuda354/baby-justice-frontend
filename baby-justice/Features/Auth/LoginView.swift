import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: BJSpacing.l) {
                header
                    .padding(.top, BJSpacing.xl)
                AuthRolePicker(selectedRole: $viewModel.selectedRole)
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
                        .foregroundStyle(Color.bjPrimaryDark)
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

    @ViewBuilder
    private var header: some View {
        if viewModel.selectedRole == .parent {
            AuthHeader(
                icon: "person.crop.circle.badge.checkmark",
                title: "Miło Cię znów widzieć",
                subtitle: "Zaloguj się, aby zarządzać zadaniami i nagrodami swojej rodziny."
            )
        } else {
            AuthHeader(
                icon: "gamecontroller.fill",
                title: "Hej, dobrze Cię widzieć!",
                subtitle: "Wpisz swój e-mail i hasło — i ruszamy zbierać punkty."
            )
        }
    }
}
