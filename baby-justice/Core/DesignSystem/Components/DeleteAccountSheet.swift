import SwiftUI

struct DeleteAccountSheet: View {
    let consequences: String
    let performDeletion: (String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var isDeleting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BJSpacing.l) {
                    warningHeader
                    consequencesCard
                    FormTextField(label: "Hasło", text: $password, secure: true)
                    if let errorMessage {
                        errorBanner(errorMessage)
                    }
                    deleteButton
                }
                .padding(BJSpacing.l)
            }
            .navigationTitle("Usunięcie konta")
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

    private var warningHeader: some View {
        VStack(spacing: BJSpacing.m) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.bjDanger)
                .padding(BJSpacing.l)
                .background(Color.bjDanger.opacity(0.12))
                .clipShape(Circle())
            Text("Czy na pewno chcesz usunąć konto?")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, BJSpacing.l)
    }

    private var consequencesCard: some View {
        Text(consequences)
            .font(.subheadline)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BJSpacing.l)
            .background(Color.bjDanger.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: BJRadius.card, style: .continuous))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: BJSpacing.s) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color.bjDanger)
            Text(message)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.bjDanger)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(BJSpacing.m)
        .background(Color.bjDanger.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: BJRadius.field, style: .continuous))
    }

    private var deleteButton: some View {
        PrimaryButton(title: "Usuń konto na zawsze", isLoading: isDeleting, background: .bjDanger) {
            Task { await deleteAccount() }
        }
        .disabled(password.isEmpty || isDeleting)
        .opacity(password.isEmpty ? 0.5 : 1)
    }

    private func deleteAccount() async {
        isDeleting = true
        errorMessage = nil
        do {
            try await performDeletion(password)
            SessionStore.shared.logout()
        } catch {
            errorMessage = deletionErrorMessage(for: error)
            isDeleting = false
        }
    }

    private func deletionErrorMessage(for error: Error) -> String {
        if case APIError.unauthorized = error {
            return "Nieprawidłowe hasło. Spróbuj ponownie."
        }
        return error.localizedDescription
    }
}
