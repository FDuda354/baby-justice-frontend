import Foundation
import Observation

@Observable
final class AuthViewModel {
    var selectedRole: Role = .parent {
        didSet { handleRoleChange(from: oldValue) }
    }

    var loginEmail = ""
    var loginPassword = ""

    var familyName = ""
    var parentName = ""
    var childName = ""
    var childBirthDate = Calendar.current.date(byAdding: .year, value: -8, to: Date()) ?? Date()
    var registerEmail = ""
    var registerPassword = ""
    var registerPasswordRepeat = ""
    var registeredAuth: AuthResponse?

    var resetEmail = ""
    var resetRequestSent = false

    var isLoading = false
    var errorMessage: String?

    func clearError() {
        errorMessage = nil
    }

    func login() async {
        errorMessage = nil
        let email = trimmed(loginEmail).lowercased()
        guard !email.isEmpty, !loginPassword.isEmpty else {
            errorMessage = "Podaj adres e-mail i hasło."
            return
        }
        guard isValidEmail(email) else {
            errorMessage = "Podaj poprawny adres e-mail."
            return
        }
        await run(invalidCredentialsMessage: "Nieprawidłowy e-mail lub hasło.") {
            let auth = try await APIClient.shared.login(email: email, password: self.loginPassword)
            SessionStore.shared.startSession(auth)
        }
    }

    func register() async {
        switch selectedRole {
        case .parent: await registerParent()
        case .child: await registerChild()
        }
    }

    func startRegisteredSession() {
        guard let auth = registeredAuth else { return }
        SessionStore.shared.startSession(auth)
    }

    func requestPasswordReset() async {
        errorMessage = nil
        let email = trimmed(resetEmail).lowercased()
        guard isValidEmail(email) else {
            errorMessage = "Podaj poprawny adres e-mail."
            return
        }
        await run(invalidCredentialsMessage: nil) {
            try await APIClient.shared.requestPasswordReset(email: email)
            self.resetRequestSent = true
        }
    }

    private func registerParent() async {
        errorMessage = nil
        let family = trimmed(familyName)
        let parent = trimmed(parentName)
        let email = trimmed(registerEmail).lowercased()
        guard !family.isEmpty else {
            errorMessage = "Podaj nazwę rodziny."
            return
        }
        guard !parent.isEmpty else {
            errorMessage = "Podaj swoje imię."
            return
        }
        guard isValidEmail(email) else {
            errorMessage = "Podaj poprawny adres e-mail."
            return
        }
        guard registerPassword.count >= 8 else {
            errorMessage = "Hasło musi mieć co najmniej 8 znaków."
            return
        }
        guard registerPassword == registerPasswordRepeat else {
            errorMessage = "Hasła różnią się od siebie."
            return
        }
        await run(invalidCredentialsMessage: nil) {
            self.registeredAuth = try await APIClient.shared.registerParent(
                familyName: family,
                parentName: parent,
                email: email,
                password: self.registerPassword
            )
        }
    }

    private func registerChild() async {
        errorMessage = nil
        let name = trimmed(childName)
        let email = trimmed(registerEmail).lowercased()
        guard !name.isEmpty else {
            errorMessage = "Podaj swoje imię."
            return
        }
        guard isValidEmail(email) else {
            errorMessage = "Podaj poprawny adres e-mail."
            return
        }
        guard registerPassword.count >= 4 else {
            errorMessage = "Hasło musi mieć co najmniej 4 znaki."
            return
        }
        guard registerPassword == registerPasswordRepeat else {
            errorMessage = "Hasła różnią się od siebie."
            return
        }
        await run(invalidCredentialsMessage: nil) {
            self.registeredAuth = try await APIClient.shared.registerChild(
                name: name,
                birthDate: Formatters.isoDay(from: self.childBirthDate),
                email: email,
                password: self.registerPassword
            )
        }
    }

    private func handleRoleChange(from oldRole: Role) {
        guard oldRole != selectedRole else { return }
        errorMessage = nil
        registerPassword = ""
        registerPasswordRepeat = ""
    }

    private func run(invalidCredentialsMessage: String?, _ operation: () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await operation()
        } catch {
            errorMessage = friendlyMessage(for: error, invalidCredentialsMessage: invalidCredentialsMessage)
        }
    }

    private func friendlyMessage(for error: Error, invalidCredentialsMessage: String?) -> String {
        let fallback = "Coś poszło nie tak. Spróbuj ponownie."
        guard let apiError = error as? APIError else { return fallback }
        if case .unauthorized = apiError, let invalidCredentialsMessage {
            return invalidCredentialsMessage
        }
        return apiError.errorDescription ?? fallback
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@")
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".")
    }
}
