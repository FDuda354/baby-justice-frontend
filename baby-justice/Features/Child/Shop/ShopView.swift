import SwiftUI
import Observation

@Observable
final class ShopViewModel {
    var rewards: [RewardDTO] = []
    var balance = 0
    var isLoading = false
    var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let rewards = APIClient.shared.shopRewards()
            async let profile = APIClient.shared.childProfile()
            self.rewards = try await rewards
            balance = try await profile.pointsBalance
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private enum ShopSegment: Hashable {
    case shop
    case purchases
}

struct ShopView: View {
    @State private var viewModel = ShopViewModel()
    @State private var segment = ShopSegment.shop

    var body: some View {
        VStack(spacing: 0) {
            segmentPicker
            content
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Sklep")
        .task { await viewModel.load() }
    }

    private var segmentPicker: some View {
        Picker("Widok", selection: $segment) {
            Text("Sklep").tag(ShopSegment.shop)
            Text("Moje zakupy").tag(ShopSegment.purchases)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, BJSpacing.l)
        .padding(.vertical, BJSpacing.s)
    }

    @ViewBuilder
    private var content: some View {
        switch segment {
        case .shop:
            shopContent
        case .purchases:
            PurchasesView()
        }
    }

    @ViewBuilder
    private var shopContent: some View {
        if viewModel.isLoading && viewModel.rewards.isEmpty {
            loadingState
        } else if let message = viewModel.errorMessage, viewModel.rewards.isEmpty {
            errorState(message: message)
        } else if viewModel.rewards.isEmpty {
            emptyState
        } else {
            rewardsGrid
        }
    }

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView("Ładowanie sklepu…")
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func errorState(message: String) -> some View {
        VStack {
            ErrorBanner(message: message) {
                Task { await viewModel.load() }
            }
            Spacer()
        }
        .padding(.top, BJSpacing.l)
    }

    private var emptyState: some View {
        ScrollView {
            EmptyStateView(
                icon: "gift.fill",
                title: "Sklep jest jeszcze pusty",
                message: "Poproś rodzica o dodanie nagród, na które będziesz zbierać punkty!"
            )
            .padding(.top, BJSpacing.xxl)
        }
        .refreshable { await viewModel.load() }
    }

    private var rewardsGrid: some View {
        ScrollView {
            VStack(spacing: BJSpacing.l) {
                if let message = viewModel.errorMessage {
                    ErrorBanner(message: message) {
                        Task { await viewModel.load() }
                    }
                }
                VStack(spacing: BJSpacing.l) {
                    balanceHeader
                    LazyVGrid(columns: gridColumns, spacing: BJSpacing.m) {
                        ForEach(viewModel.rewards) { reward in
                            NavigationLink {
                                RewardDetailView(reward: reward, balance: viewModel.balance) {
                                    Task { await viewModel.load() }
                                }
                            } label: {
                                ShopRewardCard(reward: reward, balance: viewModel.balance)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, BJSpacing.l)
            }
            .padding(.vertical, BJSpacing.s)
            .padding(.bottom, BJSpacing.xl)
        }
        .refreshable { await viewModel.load() }
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: BJSpacing.m),
            GridItem(.flexible(), spacing: BJSpacing.m)
        ]
    }

    private var balanceHeader: some View {
        CardView {
            HStack {
                Text("Twoje punkty")
                    .font(.headline)
                Spacer()
                PointsBadge(points: viewModel.balance)
                    .font(.title3)
            }
        }
    }
}

struct ShopRewardCard: View {
    let reward: RewardDTO
    let balance: Int

    private var isAffordable: Bool { balance >= reward.costPoints }
    private var missingPoints: Int { reward.costPoints - balance }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: BJSpacing.s) {
                imageSection
                Text(reward.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2, reservesSpace: true)
                PointsBadge(points: reward.costPoints)
                    .font(.subheadline)
                if !isAffordable {
                    Text("Brakuje Ci \(missingPoints) pkt")
                        .font(.caption)
                        .foregroundStyle(Color.bjDanger)
                }
            }
        }
        .opacity(isAffordable ? 1 : 0.75)
    }

    private var imageSection: some View {
        ZStack {
            rewardImage
            if !isAffordable {
                Color.black.opacity(0.3)
                Image(systemName: "lock.fill")
                    .font(.title)
                    .foregroundStyle(.white)
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: BJRadius.small, style: .continuous))
    }

    @ViewBuilder
    private var rewardImage: some View {
        if reward.hasImage {
            RemoteImageView(path: "/api/images/rewards/\(reward.id)")
        } else {
            ZStack {
                Color.bjMint
                Image(systemName: "gift.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.bjPrimary)
            }
        }
    }
}
