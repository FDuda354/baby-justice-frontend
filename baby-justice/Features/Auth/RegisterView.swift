import SwiftUI

struct RegisterView: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        ScrollView {
            if let auth = viewModel.registeredAuth {
                successView(for: auth)
            } else {
                registrationForm
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Rejestracja")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.registeredAuth != nil)
        .onAppear { viewModel.clearError() }
    }

    private var registrationForm: some View {
        VStack(spacing: BJSpacing.l) {
            header
                .padding(.top, BJSpacing.xl)
            AuthRolePicker(selectedRole: $viewModel.selectedRole)
            fields
            if let message = viewModel.errorMessage {
                AuthErrorLabel(message: message)
            }
            PrimaryButton(title: "Załóż konto", isLoading: viewModel.isLoading) {
                Task { await viewModel.register() }
            }
        }
        .padding(BJSpacing.l)
    }

    @ViewBuilder
    private var header: some View {
        if viewModel.selectedRole == .parent {
            AuthHeader(
                icon: "house.and.flag.fill",
                title: "Załóż rodzinę",
                subtitle: "Jedno konto rodzica, wspólne zadania i nagrody dla całej rodziny."
            )
        } else {
            AuthHeader(
                icon: "person.crop.circle.badge.plus",
                title: "Załóż swoje konto",
                subtitle: "Podaj swój e-mail i hasło, a po rejestracji dostaniesz swój kod dziecka dla rodzica."
            )
        }
    }

    @ViewBuilder
    private var fields: some View {
        if viewModel.selectedRole == .parent {
            parentFields
        } else {
            childFields
        }
    }

    private var parentFields: some View {
        VStack(spacing: BJSpacing.m) {
            FormTextField(label: "Nazwa rodziny", text: $viewModel.familyName)
            FormTextField(label: "Twoje imię", text: $viewModel.parentName)
            FormTextField(label: "E-mail", text: $viewModel.registerEmail, keyboard: .emailAddress)
            FormTextField(label: "Hasło (min. 8 znaków)", text: $viewModel.registerPassword, secure: true)
            FormTextField(label: "Powtórz hasło", text: $viewModel.registerPasswordRepeat, secure: true)
        }
    }

    private var childFields: some View {
        VStack(spacing: BJSpacing.m) {
            FormTextField(label: "Twoje imię", text: $viewModel.childName)
            birthDateField
            FormTextField(label: "E-mail", text: $viewModel.registerEmail, keyboard: .emailAddress)
            FormTextField(label: "Hasło (min. 4 znaki)", text: $viewModel.registerPassword, secure: true)
            FormTextField(label: "Powtórz hasło", text: $viewModel.registerPasswordRepeat, secure: true)
        }
    }

    private var birthDateField: some View {
        VStack(alignment: .leading, spacing: BJSpacing.xs) {
            Text("Data urodzenia")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            DatePicker("Data urodzenia", selection: $viewModel.childBirthDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "pl_PL"))
                .padding(.horizontal, BJSpacing.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: BJSize.fieldHeight)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: BJRadius.field, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: BJRadius.field, style: .continuous)
                        .strokeBorder(Color.bjPrimary.opacity(0.2), lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private func successView(for auth: AuthResponse) -> some View {
        if auth.role == .parent {
            ParentRegistrationSuccessView(auth: auth) {
                viewModel.startRegisteredSession()
            }
        } else {
            ChildRegistrationSuccessView(auth: auth) {
                viewModel.startRegisteredSession()
            }
        }
    }
}

private struct ParentRegistrationSuccessView: View {
    let auth: AuthResponse
    let start: () -> Void

    var body: some View {
        VStack(spacing: BJSpacing.xl) {
            AuthHeader(
                icon: "checkmark.seal.fill",
                title: "Rodzina \(auth.familyName ?? "") założona!",
                subtitle: "Witaj, \(auth.displayName). Wszystko gotowe."
            )
            .padding(.top, BJSpacing.xl)
            nextStepCard
            PrimaryButton(title: "Zaczynamy", action: start)
        }
        .padding(BJSpacing.l)
    }

    private var nextStepCard: some View {
        VStack(spacing: BJSpacing.m) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 36))
                .foregroundStyle(Color.bjPrimaryDark)
            Text("Jak dodać dzieci?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.bjPrimaryDark)
            Text("Każde dziecko zakłada własne konto w aplikacji i dostaje swój kod dziecka. Wpisz ten kod w zakładce Dzieci, aby dodać je do rodziny.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(BJSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color.bjMint)
        .clipShape(RoundedRectangle(cornerRadius: BJRadius.card, style: .continuous))
    }
}

private struct ChildRegistrationSuccessView: View {
    let auth: AuthResponse
    let start: () -> Void

    @State private var codeCopied = false

    var body: some View {
        VStack(spacing: BJSpacing.xl) {
            AuthHeader(
                icon: "party.popper.fill",
                title: "Brawo, \(auth.displayName)!",
                subtitle: "Twoje konto jest gotowe. Oto Twój kod dziecka."
            )
            .padding(.top, BJSpacing.xl)
            childCodeCard
            PrimaryButton(title: "Zaczynamy", action: start)
        }
        .padding(BJSpacing.l)
    }

    private var childCodeCard: some View {
        VStack(spacing: BJSpacing.m) {
            Text("Twój kod dziecka")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.bjPrimaryDark)
            Text(auth.childCode ?? "")
                .font(.system(size: 44, weight: .heavy, design: .monospaced))
                .kerning(6)
                .foregroundStyle(Color.bjInk)
            Button {
                copyCode()
            } label: {
                Label(codeCopied ? "Skopiowano" : "Kopiuj kod", systemImage: codeCopied ? "checkmark" : "doc.on.doc")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.bjPrimaryDark)
            }
            Text("Podaj ten kod rodzicowi — doda Cię nim do rodziny. Znajdziesz go też później w swoim profilu.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(BJSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color.bjMint)
        .clipShape(RoundedRectangle(cornerRadius: BJRadius.card, style: .continuous))
    }

    private func copyCode() {
        UIPasteboard.general.string = auth.childCode
        codeCopied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            codeCopied = false
        }
    }
}
