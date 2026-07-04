import SwiftUI

struct ForgotPasswordView: View {
    @Bindable var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            if viewModel.resetRequestSent {
                confirmation
            } else {
                requestForm
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Reset hasła")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.clearError()
            viewModel.resetRequestSent = false
        }
    }

    private var requestForm: some View {
        VStack(spacing: BJSpacing.l) {
            AuthHeader(
                icon: "key.fill",
                title: "Nie pamiętasz hasła?",
                subtitle: "Podaj adres e-mail swojego konta, a wyślemy Ci link do ustawienia nowego hasła."
            )
            .padding(.top, BJSpacing.xl)
            FormTextField(label: "E-mail", text: $viewModel.resetEmail, keyboard: .emailAddress)
            if let message = viewModel.errorMessage {
                AuthErrorLabel(message: message)
            }
            PrimaryButton(title: "Wyślij link", isLoading: viewModel.isLoading) {
                Task { await viewModel.requestPasswordReset() }
            }
        }
        .padding(BJSpacing.l)
    }

    private var confirmation: some View {
        VStack(spacing: BJSpacing.xl) {
            AuthHeader(
                icon: "envelope.badge.fill",
                title: "Sprawdź skrzynkę",
                subtitle: "Jeśli konto istnieje, wysłaliśmy e-mail z linkiem do zresetowania hasła. Link jest ważny przez godzinę."
            )
            .padding(.top, BJSpacing.xl)
            PrimaryButton(title: "Wróć do logowania") {
                dismiss()
            }
        }
        .padding(BJSpacing.l)
    }
}
