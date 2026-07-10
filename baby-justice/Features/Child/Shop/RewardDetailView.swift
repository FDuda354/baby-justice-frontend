import SwiftUI

struct RewardDetailView: View {
    let reward: RewardDTO
    let balance: Int
    var onPurchased: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var showPurchaseConfirmation = false
    @State private var isPurchasing = false
    @State private var purchaseCompleted = false
    @State private var errorMessage: String?
    @State private var purchaseToken = UUID().uuidString

    private var isAffordable: Bool { balance >= reward.costPoints }
    private var missingPoints: Int { reward.costPoints - balance }

    var body: some View {
        Group {
            if purchaseCompleted {
                successContent
            } else {
                detailContent
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(reward.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var detailContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BJSpacing.l) {
                heroImage
                infoSection
                    .padding(.horizontal, BJSpacing.l)
                balanceCard
                    .padding(.horizontal, BJSpacing.l)
                if let errorMessage {
                    ErrorBanner(message: errorMessage) {
                        Task { await purchase() }
                    }
                }
                purchaseSection
                    .padding(.horizontal, BJSpacing.l)
            }
            .padding(.bottom, BJSpacing.xl)
        }
        .alert("Kupić „\(reward.name)” za \(reward.costPoints) pkt?", isPresented: $showPurchaseConfirmation) {
            Button("Tak, kupuję!") {
                Task { await purchase() }
            }
            Button("Jeszcze nie", role: .cancel) {}
        } message: {
            Text("Punkty zostaną odjęte z Twojego konta.")
        }
    }

    private var heroImage: some View {
        ZStack {
            if reward.hasImage {
                RemoteImageView(path: "/api/images/rewards/\(reward.id)")
            } else {
                Color.bjMint
                Image(systemName: "gift.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.bjPrimary)
            }
        }
        .frame(height: 260)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: BJSpacing.s) {
            HStack(alignment: .top) {
                Text(reward.name)
                    .font(.title2.bold())
                Spacer()
                PointsBadge(points: reward.costPoints)
                    .font(.title3)
            }
            StatusChip(text: reward.rewardType.displayName, color: .bjAccent)
            if !reward.description.isEmpty {
                Text(reward.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var balanceCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: BJSpacing.s) {
                HStack {
                    Text("Twoje punkty")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(balance) / \(reward.costPoints)")
                        .font(.subheadline.bold())
                        .foregroundStyle(isAffordable ? Color.bjPrimary : Color.bjAmber)
                }
                ProgressView(value: progressValue)
                    .tint(isAffordable ? Color.bjPrimary : Color.bjAmber)
                if !isAffordable {
                    Text("Brakuje Ci \(missingPoints) pkt — zrób jeszcze kilka zadań!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var progressValue: Double {
        guard reward.costPoints > 0 else { return 1 }
        return min(Double(balance) / Double(reward.costPoints), 1)
    }

    private var purchaseSection: some View {
        PrimaryButton(title: "Kupuję! (−\(reward.costPoints) pkt)", isLoading: isPurchasing) {
            showPurchaseConfirmation = true
        }
        .disabled(!isAffordable)
        .opacity(isAffordable ? 1 : 0.5)
    }

    private var successContent: some View {
        VStack(spacing: BJSpacing.xl) {
            Spacer()
            Image(systemName: "party.popper.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.bjAmber)
                .padding(BJSpacing.xl)
                .background(Color.bjMint)
                .clipShape(Circle())
            VStack(spacing: BJSpacing.s) {
                Text("Kupione!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.bjAccent)
                Text("Rodzic wyda Ci nagrodę.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            PrimaryButton(title: "Super!") {
                dismiss()
            }
            .padding(.horizontal, BJSpacing.l)
            .padding(.bottom, BJSpacing.l)
        }
        .frame(maxWidth: .infinity)
    }

    private func purchase() async {
        isPurchasing = true
        errorMessage = nil
        do {
            _ = try await APIClient.shared.purchaseReward(rewardId: reward.id, purchaseToken: purchaseToken)
            onPurchased()
            withAnimation { purchaseCompleted = true }
        } catch {
            errorMessage = error.localizedDescription
        }
        isPurchasing = false
    }
}
