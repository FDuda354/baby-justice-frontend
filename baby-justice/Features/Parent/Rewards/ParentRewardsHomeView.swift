import SwiftUI
import Observation

@Observable
final class ParentRewardsHomeViewModel {
    var children: [ChildDTO] = []
    var deliveriesCount = 0
    var selectedChildId: Int64?
    var rewards: [RewardDTO] = []
    var showArchived = false
    var isLoading = false
    var isLoadingRewards = false
    var errorMessage: String?
    var rewardsErrorMessage: String?
    private(set) var hasLoadedOnce = false

    var selectedChild: ChildDTO? {
        children.first { $0.id == selectedChildId }
    }

    func loadIfNeeded() async {
        guard !hasLoadedOnce else { return }
        await load()
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let childrenCall = APIClient.shared.children()
            async let deliveriesCall = APIClient.shared.deliveries()
            children = try await childrenCall
            deliveriesCount = try await deliveriesCall.count
            hasLoadedOnce = true
            clearSelectionIfChildRemoved()
            await loadRewards()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func refreshSilently() async {
        guard hasLoadedOnce else { return }
        async let childrenCall = APIClient.shared.children()
        async let deliveriesCall = APIClient.shared.deliveries()
        if let freshChildren = try? await childrenCall {
            children = freshChildren
            clearSelectionIfChildRemoved()
        }
        if let freshDeliveries = try? await deliveriesCall {
            deliveriesCount = freshDeliveries.count
        }
        await loadRewards()
    }

    func selectChild(_ childId: Int64) {
        guard selectedChildId != childId else { return }
        selectedChildId = childId
        rewards = []
        Task {
            await loadRewards()
        }
    }

    func loadRewards() async {
        guard let selectedChildId else {
            rewards = []
            return
        }
        isLoadingRewards = true
        rewardsErrorMessage = nil
        do {
            rewards = try await APIClient.shared.rewards(childId: selectedChildId, includeArchived: showArchived)
        } catch {
            rewardsErrorMessage = error.localizedDescription
        }
        isLoadingRewards = false
    }

    private func clearSelectionIfChildRemoved() {
        if let selectedChildId, !children.contains(where: { $0.id == selectedChildId }) {
            self.selectedChildId = nil
            rewards = []
        }
    }
}

struct ParentRewardsHomeView: View {
    @State private var viewModel = ParentRewardsHomeViewModel()
    @State private var showsAddReward = false

    var body: some View {
        Group {
            if viewModel.isLoading && !viewModel.hasLoadedOnce {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasLoadedOnce {
                ErrorBanner(message: errorMessage) {
                    Task {
                        await viewModel.load()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    content
                }
                .refreshable {
                    await viewModel.load()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Nagrody")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showsAddReward = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(viewModel.selectedChildId == nil)
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .onAppear {
            Task {
                await viewModel.refreshSilently()
            }
        }
        .onChange(of: viewModel.showArchived) { _, _ in
            Task {
                await viewModel.loadRewards()
            }
        }
        .sheet(isPresented: $showsAddReward) {
            if let childId = viewModel.selectedChildId {
                AddRewardView(childId: childId) {
                    Task {
                        await viewModel.loadRewards()
                    }
                }
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: BJSpacing.l) {
            deliveriesEntryCard
            SectionHeader(title: "Sklepiki dzieci")
            childrenSection
        }
        .padding(BJSpacing.l)
    }

    private var deliveriesEntryCard: some View {
        NavigationLink {
            DeliveriesView()
        } label: {
            CardView {
                HStack(spacing: BJSpacing.m) {
                    Image(systemName: "shippingbox.fill")
                        .font(.title2)
                        .foregroundStyle(Color.bjPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.bjMint)
                        .clipShape(RoundedRectangle(cornerRadius: BJRadius.small, style: .continuous))
                    VStack(alignment: .leading, spacing: BJSpacing.xs) {
                        Text("Do wydania (\(viewModel.deliveriesCount))")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("Kupione nagrody czekające na wydanie")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var childrenSection: some View {
        if viewModel.children.isEmpty {
            EmptyStateView(
                icon: "person.2",
                title: "Brak dzieci",
                message: "Dodaj dziecko w zakładce Dzieci, aby stworzyć jego sklepik nagród."
            )
        } else {
            childChips
            rewardsSection
        }
    }

    private var childChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BJSpacing.m) {
                ForEach(viewModel.children) { child in
                    ChildChipView(child: child, isSelected: child.id == viewModel.selectedChildId) {
                        viewModel.selectChild(child.id)
                    }
                }
            }
            .padding(.vertical, BJSpacing.xs)
        }
    }

    @ViewBuilder
    private var rewardsSection: some View {
        if let child = viewModel.selectedChild {
            Toggle("Pokaż zarchiwizowane", isOn: $viewModel.showArchived)
                .font(.subheadline.weight(.medium))
                .tint(Color.bjPrimary)
            if viewModel.isLoadingRewards && viewModel.rewards.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(BJSpacing.xl)
            } else if let rewardsErrorMessage = viewModel.rewardsErrorMessage {
                ErrorBanner(message: rewardsErrorMessage) {
                    Task {
                        await viewModel.loadRewards()
                    }
                }
            } else if viewModel.rewards.isEmpty {
                EmptyStateView(
                    icon: "gift",
                    title: "Pusty sklepik",
                    message: "Dodaj pierwszą nagrodę dla \(child.name) przyciskiem plusa."
                )
            } else {
                rewardsList
            }
        } else {
            EmptyStateView(
                icon: "hand.point.up.left",
                title: "Wybierz dziecko",
                message: "Dotknij awatara powyżej, aby zobaczyć sklepik nagród dziecka."
            )
        }
    }

    private var rewardsList: some View {
        VStack(spacing: BJSpacing.m) {
            ForEach(viewModel.rewards) { reward in
                NavigationLink {
                    RewardDetailsView(rewardId: reward.id)
                } label: {
                    RewardRowView(reward: reward)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ChildChipView: View {
    let child: ChildDTO
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BJSpacing.s) {
                AvatarView(hasAvatar: child.hasAvatar, childId: child.id, size: 32)
                Text(child.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
            }
            .padding(.horizontal, BJSpacing.m)
            .padding(.vertical, BJSpacing.s)
            .background(isSelected ? Color.bjPrimary : Color(.secondarySystemGroupedBackground))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.bjPrimaryDark : Color.bjPrimary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct RewardRowView: View {
    let reward: RewardDTO

    var body: some View {
        CardView {
            HStack(spacing: BJSpacing.m) {
                thumbnail
                VStack(alignment: .leading, spacing: BJSpacing.xs) {
                    Text(reward.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    HStack(spacing: BJSpacing.s) {
                        StatusChip(text: reward.rewardType.displayName, color: .bjAccent)
                        if reward.status != .active {
                            StatusChip(text: reward.status.displayName, color: rewardStatusColor(reward.status))
                        }
                    }
                }
                Spacer()
                PointsBadge(points: reward.costPoints)
            }
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if reward.hasImage {
            RemoteImageView(path: "/api/images/rewards/\(reward.id)")
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: BJRadius.small, style: .continuous))
        } else {
            Image(systemName: "gift.fill")
                .font(.title3)
                .foregroundStyle(Color.bjPrimary)
                .frame(width: 56, height: 56)
                .background(Color.bjMint)
                .clipShape(RoundedRectangle(cornerRadius: BJRadius.small, style: .continuous))
        }
    }
}

private func rewardStatusColor(_ status: RewardStatus) -> Color {
    switch status {
    case .active: .bjPrimary
    case .purchased: .blue
    case .archived: .gray
    }
}
