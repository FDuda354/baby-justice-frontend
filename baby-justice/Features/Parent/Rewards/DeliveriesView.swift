import SwiftUI
import Observation

@Observable
final class DeliveriesViewModel {
    var deliveries: [RewardPurchaseDTO] = []
    var isLoading = false
    var errorMessage: String?
    var actionErrorMessage: String?
    var deliveringIds: Set<Int64> = []
    private(set) var hasLoadedOnce = false

    func loadIfNeeded() async {
        guard !hasLoadedOnce else { return }
        await load()
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            deliveries = try await APIClient.shared.deliveries()
            hasLoadedOnce = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func markDelivered(_ purchase: RewardPurchaseDTO) async {
        guard !deliveringIds.contains(purchase.id) else { return }
        deliveringIds.insert(purchase.id)
        actionErrorMessage = nil
        deliveries.removeAll { $0.id == purchase.id }
        do {
            try await APIClient.shared.markDelivered(purchaseId: purchase.id)
        } catch {
            actionErrorMessage = error.localizedDescription
            await load()
        }
        deliveringIds.remove(purchase.id)
    }
}

struct DeliveriesView: View {
    @State private var viewModel = DeliveriesViewModel()

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
            } else if viewModel.deliveries.isEmpty {
                emptyContent
            } else {
                deliveriesList
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Do wydania")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var emptyContent: some View {
        ScrollView {
            VStack(spacing: BJSpacing.l) {
                if let actionErrorMessage = viewModel.actionErrorMessage {
                    ErrorBanner(message: actionErrorMessage) {
                        Task {
                            await viewModel.load()
                        }
                    }
                }
                EmptyStateView(
                    icon: "checkmark.seal.fill",
                    title: "Wszystko wydane!",
                    message: "Nie ma nagród czekających na wydanie. Dobra robota!"
                )
            }
            .padding(.top, BJSpacing.xl)
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private var deliveriesList: some View {
        List {
            if let actionErrorMessage = viewModel.actionErrorMessage {
                ErrorBanner(message: actionErrorMessage) {
                    Task {
                        await viewModel.load()
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            ForEach(viewModel.deliveries) { purchase in
                DeliveryRowView(purchase: purchase, isDelivering: viewModel.deliveringIds.contains(purchase.id)) {
                    Task {
                        await viewModel.markDelivered(purchase)
                    }
                }
                .listRowInsets(EdgeInsets(top: BJSpacing.s, leading: BJSpacing.l, bottom: BJSpacing.s, trailing: BJSpacing.l))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        Task {
                            await viewModel.markDelivered(purchase)
                        }
                    } label: {
                        Label("Wydane", systemImage: "checkmark")
                    }
                    .tint(Color.bjPrimary)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            await viewModel.load()
        }
    }
}

private struct DeliveryRowView: View {
    let purchase: RewardPurchaseDTO
    let isDelivering: Bool
    let onDeliver: () -> Void

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: BJSpacing.m) {
                HStack(spacing: BJSpacing.m) {
                    thumbnail
                    VStack(alignment: .leading, spacing: BJSpacing.xs) {
                        Text(purchase.rewardName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        Label(purchase.childName, systemImage: "person.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(Formatters.formatted(date: purchase.purchasedAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    PointsBadge(points: purchase.costPoints)
                }
                deliverButton
            }
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if purchase.rewardHasImage {
            RemoteImageView(path: "/api/images/rewards/\(purchase.rewardId)")
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

    private var deliverButton: some View {
        Button(action: onDeliver) {
            ZStack {
                if isDelivering {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Wydane ✓")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Color.bjPrimary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: BJRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDelivering)
    }
}
