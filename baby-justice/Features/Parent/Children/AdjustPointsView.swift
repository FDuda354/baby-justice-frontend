import SwiftUI

struct AdjustPointsView: View {
    let child: ChildDTO
    let onSaved: (ChildDTO) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var direction: AdjustDirection = .add
    @State private var amount = 10
    @State private var reason = ""
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BJSpacing.l) {
                    Picker("Rodzaj zmiany", selection: $direction) {
                        ForEach(AdjustDirection.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    amountField
                    FormTextField(label: "Opis", text: $reason)
                    balancePreview
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.bjDanger)
                    }
                    PrimaryButton(title: "Zapisz", isLoading: isSaving) {
                        Task { await save() }
                    }
                }
                .padding(BJSpacing.l)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Punkty: \(child.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anuluj") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var delta: Int {
        direction == .add ? amount : -amount
    }

    private var resultingBalance: Int {
        child.pointsBalance + delta
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: BJSpacing.xs) {
            Text("Liczba punktów")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            HStack(spacing: BJSpacing.m) {
                TextField("0", value: $amount, format: .number)
                    .keyboardType(.numberPad)
                    .font(.title3.bold())
                    .padding(.horizontal, BJSpacing.m)
                    .frame(height: BJSize.fieldHeight)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: BJRadius.field, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: BJRadius.field, style: .continuous)
                            .strokeBorder(Color.bjPrimary.opacity(0.2), lineWidth: 1)
                    )
                Stepper("Liczba punktów", value: $amount, in: 1...100000)
                    .labelsHidden()
            }
        }
    }

    private var balancePreview: some View {
        VStack(alignment: .leading, spacing: BJSpacing.xs) {
            HStack(spacing: BJSpacing.s) {
                Text("Saldo po zmianie:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(resultingBalance)")
                    .font(.subheadline.bold())
                    .foregroundStyle(resultingBalance < 0 ? Color.bjDanger : Color.primary)
            }
            if resultingBalance < 0 {
                Text("Saldo punktów nie może być ujemne.")
                    .font(.footnote)
                    .foregroundStyle(Color.bjDanger)
            }
        }
    }

    private func save() async {
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard amount > 0 else {
            errorMessage = "Podaj liczbę punktów większą od zera."
            return
        }
        guard !trimmedReason.isEmpty else {
            errorMessage = "Podaj opis zmiany punktów."
            return
        }
        guard resultingBalance >= 0 else {
            errorMessage = "Nie można odjąć więcej punktów, niż dziecko posiada."
            return
        }
        isSaving = true
        errorMessage = nil
        do {
            let updated = try await APIClient.shared.adjustChildPoints(
                childId: child.id,
                delta: delta,
                description: trimmedReason
            )
            onSaved(updated)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

private enum AdjustDirection: String, CaseIterable, Identifiable {
    case add
    case subtract

    var id: String { rawValue }

    var label: String {
        switch self {
        case .add: "Dodaj"
        case .subtract: "Odejmij"
        }
    }
}
