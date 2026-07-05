import SwiftUI
import Observation

@Observable
final class PurchasesViewModel {
    var purchases: [RewardPurchaseDTO] = []
    var isLoading = false
    var errorMessage: String?
    var confirmingPurchaseId: Int64?

    var activePurchases: [RewardPurchaseDTO] {
        purchases.filter { $0.status != .received }
    }

    var receivedPurchases: [RewardPurchaseDTO] {
        purchases.filter { $0.status == .received }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            purchases = try await APIClient.shared.myPurchases()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func confirmReceipt(of purchase: RewardPurchaseDTO) async {
        confirmingPurchaseId = purchase.id
        errorMessage = nil
        do {
            let updated = try await APIClient.shared.confirmReceipt(purchaseId: purchase.id)
            if let index = purchases.firstIndex(where: { $0.id == updated.id }) {
                purchases[index] = updated
            }
            ChildBadgesStore.shared.refreshSoon()
        } catch {
            errorMessage = error.localizedDescription
        }
        confirmingPurchaseId = nil
    }
}

struct PurchasesView: View {
    @State private var viewModel = PurchasesViewModel()
    @State private var showReceived = false

    var body: some View {
        content
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.purchases.isEmpty {
            loadingState
        } else if let message = viewModel.errorMessage, viewModel.purchases.isEmpty {
            errorState(message: message)
        } else if viewModel.purchases.isEmpty {
            emptyState
        } else {
            purchasesList
        }
    }

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView("Ładowanie zakupów…")
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
                icon: "bag.fill",
                title: "Nie masz jeszcze zakupów",
                message: "Zbieraj punkty za zadania i kup swoją pierwszą nagrodę w sklepie!"
            )
            .padding(.top, BJSpacing.xxl)
        }
        .refreshable { await viewModel.load() }
    }

    private var purchasesList: some View {
        ScrollView {
            VStack(spacing: BJSpacing.m) {
                if let message = viewModel.errorMessage {
                    ErrorBanner(message: message) {
                        Task { await viewModel.load() }
                    }
                }
                VStack(spacing: BJSpacing.m) {
                    ForEach(viewModel.activePurchases) { purchase in
                        ChildPurchaseCard(
                            purchase: purchase,
                            isConfirming: viewModel.confirmingPurchaseId == purchase.id
                        ) {
                            Task { await viewModel.confirmReceipt(of: purchase) }
                        }
                    }
                    if !viewModel.receivedPurchases.isEmpty {
                        receivedSection
                    }
                }
                .padding(.horizontal, BJSpacing.l)
            }
            .padding(.vertical, BJSpacing.s)
            .padding(.bottom, BJSpacing.xl)
        }
        .refreshable { await viewModel.load() }
    }

    private var receivedSection: some View {
        VStack(spacing: BJSpacing.m) {
            receivedHeader
            if showReceived {
                ForEach(viewModel.receivedPurchases) { purchase in
                    ChildPurchaseCard(purchase: purchase, isConfirming: false) {}
                }
            }
        }
    }

    private var receivedHeader: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { showReceived.toggle() }
        } label: {
            HStack {
                Text("Odebrane (\(viewModel.receivedPurchases.count))")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(showReceived ? 180 : 0))
            }
            .padding(.vertical, BJSpacing.s)
        }
        .buttonStyle(.plain)
    }
}

private struct ChildPurchaseCard: View {
    let purchase: RewardPurchaseDTO
    let isConfirming: Bool
    let onConfirmReceipt: () -> Void

    private var isDelivered: Bool { purchase.status == .delivered }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: BJSpacing.m) {
                HStack(alignment: .top, spacing: BJSpacing.m) {
                    thumbnail
                    VStack(alignment: .leading, spacing: BJSpacing.xs) {
                        Text(purchase.rewardName)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        PointsBadge(points: purchase.costPoints)
                            .font(.caption)
                        Text(Formatters.formatted(date: purchase.purchasedAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                StatusChip(text: purchase.status.displayName, color: statusColor)
                statusFooter
            }
        }
        .overlay(deliveredBorder)
    }

    @ViewBuilder
    private var deliveredBorder: some View {
        if isDelivered {
            RoundedRectangle(cornerRadius: BJRadius.card, style: .continuous)
                .stroke(Color.bjPrimary, lineWidth: 2)
        }
    }

    private var thumbnail: some View {
        ZStack {
            if purchase.rewardHasImage {
                RemoteImageView(path: "/api/images/rewards/\(purchase.rewardId)")
            } else {
                Color.bjMint
                Image(systemName: "gift.fill")
                    .font(.title3)
                    .foregroundStyle(Color.bjPrimary)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: BJRadius.small, style: .continuous))
    }

    @ViewBuilder
    private var statusFooter: some View {
        switch purchase.status {
        case .pendingDelivery:
            Text("Czekamy aż rodzic wyda nagrodę")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .delivered:
            PrimaryButton(title: "Odebrałem ✔", isLoading: isConfirming) {
                onConfirmReceipt()
            }
        case .received:
            if let receivedAt = purchase.receivedAt {
                Text("Odebrana \(Formatters.formatted(date: receivedAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusColor: Color {
        switch purchase.status {
        case .pendingDelivery: .bjAmber
        case .delivered: .blue
        case .received: .bjPrimary
        }
    }
}
