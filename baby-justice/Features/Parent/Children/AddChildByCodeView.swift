import SwiftUI

struct AddChildByCodeView: View {
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var childCode = ""
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BJSpacing.l) {
                    codeField
                    Text("Dziecko najpierw zakłada własne konto w aplikacji (na ekranie startowym wybiera „Załóż konto dziecka”) i dostaje swój kod dziecka. Wpisz ten kod powyżej, aby dodać je do rodziny.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.bjDanger)
                    }
                    PrimaryButton(title: "Dodaj do rodziny", isLoading: isSaving) {
                        Task { await save() }
                    }
                }
                .padding(BJSpacing.l)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dodaj dziecko")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anuluj") { dismiss() }
                }
            }
        }
    }

    private var codeField: some View {
        FormTextField(label: "Kod dziecka (6 znaków)", text: $childCode, keyboard: .asciiCapable)
            .onChange(of: childCode) { _, newValue in
                let normalized = Self.normalizedCode(newValue)
                if normalized != newValue {
                    childCode = normalized
                }
            }
    }

    private static func normalizedCode(_ raw: String) -> String {
        String(raw.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
    }

    private func save() async {
        guard childCode.count == 6 else {
            errorMessage = "Kod dziecka składa się z 6 znaków."
            return
        }
        isSaving = true
        errorMessage = nil
        do {
            _ = try await APIClient.shared.addChildByCode(childCode)
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
