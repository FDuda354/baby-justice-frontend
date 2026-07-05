import SwiftUI
import Observation

@Observable
final class EditRewardViewModel {
    let reward: RewardDTO
    let form = RewardFormModel()
    var isSaving = false
    var errorMessage: String?
    private var hasLoadedExistingImage = false

    init(reward: RewardDTO) {
        self.reward = reward
        form.prefill(with: reward)
    }

    func loadExistingImageIfNeeded() async {
        guard reward.hasImage, !hasLoadedExistingImage else { return }
        hasLoadedExistingImage = true
        guard form.imageData == nil else { return }
        if let data = try? await APIClient.shared.fetchImage(path: "/api/images/rewards/\(reward.id)") {
            form.loadExistingImage(data)
        }
    }

    func save() async -> RewardDTO? {
        isSaving = true
        errorMessage = nil
        do {
            let updated = try await APIClient.shared.updateReward(rewardId: reward.id, form.buildRequest())
            isSaving = false
            return updated
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
            return nil
        }
    }
}

struct EditRewardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditRewardViewModel
    private let onSaved: (RewardDTO) -> Void

    init(reward: RewardDTO, onSaved: @escaping (RewardDTO) -> Void) {
        _viewModel = State(initialValue: EditRewardViewModel(reward: reward))
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
                    PrimaryButton(title: "Zapisz zmiany", isLoading: viewModel.isSaving) {
                        Task {
                            await save()
                        }
                    }
                }
                .padding(BJSpacing.l)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edytuj nagrodę")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anuluj") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadExistingImageIfNeeded()
            }
        }
    }

    private func save() async {
        guard viewModel.form.isValid else {
            viewModel.errorMessage = "Podaj nazwę nagrody i koszt większy od zera."
            return
        }
        if let updated = await viewModel.save() {
            onSaved(updated)
            dismiss()
        }
    }
}
