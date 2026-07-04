import SwiftUI
import Observation

@Observable
final class AddRewardViewModel {
    let childId: Int64
    let form = RewardFormModel()
    var isSaving = false
    var errorMessage: String?

    init(childId: Int64) {
        self.childId = childId
    }

    func save() async -> Bool {
        isSaving = true
        errorMessage = nil
        do {
            _ = try await APIClient.shared.createReward(childId: childId, form.buildRequest())
            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
            return false
        }
    }
}

struct AddRewardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddRewardViewModel
    private let onSaved: () -> Void

    init(childId: Int64, onSaved: @escaping () -> Void) {
        _viewModel = State(initialValue: AddRewardViewModel(childId: childId))
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BJSpacing.l) {
                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(message: errorMessage) {
                            Task {
                                await save()
                            }
                        }
                    }
                    RewardFormView(model: viewModel.form)
                    PrimaryButton(title: "Dodaj nagrodę", isLoading: viewModel.isSaving) {
                        Task {
                            await save()
                        }
                    }
                }
                .padding(BJSpacing.l)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Nowa nagroda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anuluj") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func save() async {
        guard viewModel.form.isValid else {
            viewModel.errorMessage = "Podaj nazwę nagrody i koszt większy od zera."
            return
        }
        if await viewModel.save() {
            onSaved()
            dismiss()
        }
    }
}
