import SwiftUI
import Observation

@Observable
final class RewardDetailsViewModel {
    let rewardId: Int64
    var reward: RewardDTO?
    var isLoading = false
    var errorMessage: String?
    var isArchiving = false
    var actionErrorMessage: String?

    init(rewardId: Int64) {
        self.rewardId = rewardId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            reward = try await APIClient.shared.reward(rewardId: rewardId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func archive() async {
        isArchiving = true
        actionErrorMessage = nil
        do {
            try await APIClient.shared.archiveReward(rewardId: rewardId)
            await load()
        } catch {
            actionErrorMessage = error.localizedDescription
        }
        isArchiving = false
    }
}

struct RewardDetailsView: View {
    @State private var viewModel: RewardDetailsViewModel
    @State private var showsEdit = false
    @State private var showsArchiveConfirmation = false

    init(rewardId: Int64) {
        _viewModel = State(initialValue: RewardDetailsViewModel(rewardId: rewardId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.reward == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage, viewModel.reward == nil {
                ErrorBanner(message: errorMessage) {
                    Task {
                        await viewModel.load()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let reward = viewModel.reward {
                detailsContent(reward)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Nagroda")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showsEdit) {
            if let reward = viewModel.reward {
                EditRewardView(reward: reward) { updated in
                    viewModel.reward = updated
                }
            }
        }
        .confirmationDialog("Zarchiwizować nagrodę?", isPresented: $showsArchiveConfirmation, titleVisibility: .visible) {
            Button("Archiwizuj", role: .destructive) {
                Task {
                    await viewModel.archive()
                }
            }
            Button("Anuluj", role: .cancel) {}
        } message: {
            Text("Nagroda zniknie ze sklepiku dziecka. Historia zakupów pozostanie bez zmian.")
        }
    }

    private func detailsContent(_ reward: RewardDTO) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BJSpacing.l) {
                if let actionErrorMessage = viewModel.actionErrorMessage {
                    ErrorBanner(message: actionErrorMessage) {
                        Task {
                            await viewModel.archive()
                        }
                    }
                }
                if reward.hasImage {
                    RemoteImageView(path: "/api/images/rewards/\(reward.id)")
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: BJRadius.card, style: .continuous))
                }
                infoCard(reward)
                if reward.status != .archived {
                    PrimaryButton(title: "Edytuj") {
                        showsEdit = true
                    }
                    archiveButton
                }
            }
            .padding(BJSpacing.l)
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private func infoCard(_ reward: RewardDTO) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: BJSpacing.m) {
                Text(reward.name)
                    .font(.title2.bold())
                HStack(spacing: BJSpacing.s) {
                    StatusChip(text: reward.rewardType.displayName, color: .bjPrimaryDark)
                    StatusChip(text: reward.status.displayName, color: statusColor(reward.status))
                }
                HStack(spacing: BJSpacing.s) {
                    Text("Koszt:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    PointsBadge(points: reward.costPoints)
                }
                if !reward.description.isEmpty {
                    Text(reward.description)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                Text("Dodano \(Formatters.formatted(date: reward.createdAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var archiveButton: some View {
        Button {
            showsArchiveConfirmation = true
        } label: {
            ZStack {
                if viewModel.isArchiving {
                    ProgressView()
                        .tint(Color.bjDanger)
                } else {
                    Text("Archiwizuj")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: BJSize.buttonHeight)
            .background(Color.bjDanger.opacity(0.12))
            .foregroundStyle(Color.bjDanger)
            .clipShape(RoundedRectangle(cornerRadius: BJRadius.button, style: .continuous))
        }
        .disabled(viewModel.isArchiving)
    }

    private func statusColor(_ status: RewardStatus) -> Color {
        switch status {
        case .active: .bjPrimary
        case .purchased: .blue
        case .archived: .gray
        }
    }
}
