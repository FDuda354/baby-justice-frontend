import SwiftUI
import PhotosUI

struct ChildProfileView: View {
    @State private var viewModel = ChildProfileViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingPasswordSheet = false
    @State private var showingLogoutConfirmation = false
    @State private var showingDeleteAccountSheet = false
    @State private var codeCopied = false

    var body: some View {
        ScrollView {
            content
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profil")
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let newItem else { return }
            Task {
                let data = try? await newItem.loadTransferable(type: Data.self)
                selectedPhoto = nil
                if let data {
                    await viewModel.uploadAvatar(imageData: data)
                } else {
                    viewModel.actionError = "Nie udało się wczytać wybranego zdjęcia."
                }
            }
        }
        .sheet(isPresented: $showingPasswordSheet) {
            ChildChangePasswordSheet()
        }
        .sheet(isPresented: $showingDeleteAccountSheet) {
            DeleteAccountSheet(
                consequences: "Uważaj — tego nie da się cofnąć. Twoje konto, wszystkie zebrane punkty i cała historia znikną bezpowrotnie. Jeśli kiedyś zechcesz wrócić, będziesz musiał założyć konto od nowa.",
                performDeletion: { password in
                    try await APIClient.shared.deleteChildAccount(password: password)
                }
            )
        }
        .alert("Czy na pewno chcesz się wylogować?", isPresented: $showingLogoutConfirmation) {
            Button("Wyloguj się", role: .destructive) {
                SessionStore.shared.logout()
            }
            Button("Anuluj", role: .cancel) {}
        }
        .overlay {
            if viewModel.isProcessingAvatar {
                LoadingOverlay()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.profile == nil {
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.top, 120)
        } else if let profile = viewModel.profile {
            VStack(spacing: BJSpacing.l) {
                if let message = viewModel.errorMessage {
                    ErrorBanner(message: message) {
                        Task { await viewModel.load() }
                    }
                }
                VStack(spacing: BJSpacing.l) {
                    avatarSection(profile)
                    feedbackMessages
                    childCodeCard(profile)
                    familySection(profile)
                    accountCard
                    helpCard
                    logoutButton
                    deleteAccountButton
                }
                .padding(.horizontal, BJSpacing.l)
            }
            .padding(.vertical, BJSpacing.l)
        } else if let message = viewModel.errorMessage {
            ErrorBanner(message: message) {
                Task { await viewModel.load() }
            }
            .padding(.top, BJSpacing.xxl)
        }
    }

    private func avatarSection(_ profile: ChildDTO) -> some View {
        CardView {
            VStack(spacing: BJSpacing.m) {
                AvatarView(hasAvatar: profile.hasAvatar, childId: profile.id, size: 110)
                    .id(viewModel.avatarVersion)
                Text(profile.name)
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.bjInk)
                Text("E-mail: \(profile.email)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack(spacing: BJSpacing.l) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Zmień zdjęcie", systemImage: "photo.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.bjAccent)
                    }
                    if profile.hasAvatar {
                        Button {
                            Task { await viewModel.removeAvatar() }
                        } label: {
                            Label("Usuń zdjęcie", systemImage: "trash")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.bjDanger)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var feedbackMessages: some View {
        if let info = viewModel.infoMessage {
            Text(info)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.bjAccent)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        if let error = viewModel.actionError {
            Text(error)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.bjDanger)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func childCodeCard(_ profile: ChildDTO) -> some View {
        CardView {
            VStack(spacing: BJSpacing.m) {
                Text("Twój kod dziecka")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.bjAccent)
                Text(profile.childCode)
                    .font(.system(size: 34, weight: .heavy, design: .monospaced))
                    .kerning(4)
                    .foregroundStyle(Color.bjInk)
                Button {
                    copyCode(profile.childCode)
                } label: {
                    Label(codeCopied ? "Skopiowano" : "Kopiuj kod", systemImage: codeCopied ? "checkmark" : "doc.on.doc")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.bjAccent)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func familySection(_ profile: ChildDTO) -> some View {
        CardView {
            HStack(spacing: BJSpacing.m) {
                Image(systemName: "house.and.flag.fill")
                    .font(.title3)
                    .foregroundStyle(Color.bjPrimary)
                if let familyName = profile.familyName {
                    Text("Rodzina: \(familyName)")
                        .font(.subheadline.weight(.semibold))
                } else {
                    Text("Nie należysz jeszcze do żadnej rodziny. Podaj rodzicowi swój kod dziecka, a doda Cię do rodziny.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var accountCard: some View {
        CardView {
            Button {
                viewModel.clearFeedback()
                showingPasswordSheet = true
            } label: {
                HStack(spacing: BJSpacing.m) {
                    Image(systemName: "key.fill")
                        .foregroundStyle(Color.bjPrimary)
                        .frame(width: 28)
                    Text("Zmień hasło")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var helpCard: some View {
        CardView {
            NavigationLink {
                HelpView()
            } label: {
                HStack(spacing: BJSpacing.m) {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(Color.bjPrimary)
                        .frame(width: 28)
                    Text("Jak korzystać z aplikacji")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var logoutButton: some View {
        Button {
            showingLogoutConfirmation = true
        } label: {
            Label("Wyloguj się", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: BJSize.buttonHeight)
                .background(Color.bjDanger)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: BJRadius.button, style: .continuous))
        }
    }

    private var deleteAccountButton: some View {
        Button {
            showingDeleteAccountSheet = true
        } label: {
            Label("Usuń konto", systemImage: "trash.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.bjDanger)
                .frame(maxWidth: .infinity)
                .frame(height: BJSize.buttonHeight)
        }
    }

    private func copyCode(_ code: String) {
        UIPasteboard.general.string = code
        codeCopied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            codeCopied = false
        }
    }
}

private struct ChildChangePasswordSheet: View {
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
                    Text("Nowe hasło musi mieć co najmniej 4 znaki.")
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
        !currentPassword.isEmpty && newPassword.count >= 4 && repeatedPassword == newPassword && !isSaving
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            try await APIClient.shared.changeChildPassword(current: currentPassword, new: newPassword)
            dismiss()
        } catch {
            if case APIError.unauthorized = error {
                errorMessage = "Obecne hasło jest nieprawidłowe."
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isSaving = false
    }
}
