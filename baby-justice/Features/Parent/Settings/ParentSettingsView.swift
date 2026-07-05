import SwiftUI

struct ParentSettingsView: View {
    @State private var viewModel = ParentSettingsViewModel()
    @State private var showPasswordSheet = false
    @State private var showLogoutConfirmation = false
    @State private var showDeleteAccountSheet = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.family == nil {
                ProgressView("Wczytywanie…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let loadError = viewModel.loadErrorMessage, viewModel.family == nil {
                ScrollView {
                    ErrorBanner(message: loadError) {
                        Task { await viewModel.load() }
                    }
                    .padding(.top, BJSpacing.xl)
                }
            } else {
                settingsForm
            }
        }
        .navigationTitle("Ustawienia")
        .task {
            await viewModel.loadIfNeeded()
        }
        .sheet(isPresented: $showPasswordSheet) {
            ChangePasswordSheet()
        }
        .sheet(isPresented: $showDeleteAccountSheet) {
            DeleteAccountSheet(
                consequences: "Usunięcie konta jest nieodwracalne. Twoja rodzina, wszystkie zadania, nagrody i cała historia rodziny znikną bezpowrotnie. Konta dzieci NIE zostaną usunięte — zostaną jedynie odłączone od rodziny i zachowają swoje punkty oraz historię.",
                performDeletion: { password in
                    try await APIClient.shared.deleteParentAccount(password: password)
                }
            )
        }
        .alert("Czy na pewno chcesz się wylogować?", isPresented: $showLogoutConfirmation) {
            Button("Wyloguj się", role: .destructive) {
                SessionStore.shared.logout()
            }
            Button("Anuluj", role: .cancel) {}
        }
        .alert("Nie udało się zapisać", isPresented: actionErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.actionErrorMessage ?? "")
        }
    }

    private var settingsForm: some View {
        Form {
            familySection
            accountSection
            logoutSection
            deleteAccountSection
        }
    }

    private var familySection: some View {
        Section {
            TextField("Nazwa rodziny", text: $viewModel.familyName)
            Button {
                Task { await viewModel.saveFamilyName() }
            } label: {
                if viewModel.isSavingName {
                    ProgressView()
                } else {
                    Text("Zapisz nazwę")
                }
            }
            .disabled(!viewModel.canSaveFamilyName)
        } header: {
            Text("Rodzina")
        }
    }

    private var accountSection: some View {
        Section {
            LabeledContent("E-mail", value: viewModel.family?.parentEmail ?? "—")
            Button("Zmień hasło") {
                showPasswordSheet = true
            }
        } header: {
            Text("Konto")
        }
    }

    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                Label("Wyloguj się", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    private var deleteAccountSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteAccountSheet = true
            } label: {
                Label("Usuń konto", systemImage: "trash.fill")
            }
        } footer: {
            Text("Trwałe usunięcie konta rodzica wraz z rodziną.")
        }
    }

    private var actionErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.actionErrorMessage != nil },
            set: { presented in
                if !presented {
                    viewModel.actionErrorMessage = nil
                }
            }
        )
    }

}

private struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var repeatedPassword = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Obecne hasło", text: $currentPassword)
                    SecureField("Nowe hasło", text: $newPassword)
                    SecureField("Powtórz nowe hasło", text: $repeatedPassword)
                } footer: {
                    Text("Nowe hasło musi mieć co najmniej 8 znaków.")
                }

                if showsMismatchHint {
                    Section {
                        Text("Hasła muszą być takie same.")
                            .font(.footnote)
                            .foregroundStyle(Color.bjDanger)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color.bjDanger)
                    }
                }

                Section {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Zmień hasło")
                        }
                    }
                    .disabled(!canSave)
                }
            }
            .navigationTitle("Zmiana hasła")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var showsMismatchHint: Bool {
        !repeatedPassword.isEmpty && repeatedPassword != newPassword
    }

    private var canSave: Bool {
        !currentPassword.isEmpty && newPassword.count >= 8 && repeatedPassword == newPassword && !isSaving
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            try await APIClient.shared.changeParentPassword(currentPassword: currentPassword, newPassword: newPassword)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
