import SwiftUI

struct ChildNotificationsView: View {
    @State private var viewModel = ChildNotificationsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Sprawdzam nowości...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                ScrollView {
                    ErrorBanner(message: errorMessage) {
                        Task { await viewModel.load() }
                    }
                    .padding(.top, BJSpacing.xl)
                }
            } else if viewModel.notifications.isEmpty {
                ScrollView {
                    EmptyStateView(
                        icon: "bell",
                        title: "Cisza w eterze!",
                        message: "Nowe wieści pojawią się tutaj. Leć zdobywać punkty!"
                    )
                }
                .refreshable { await viewModel.load() }
            } else {
                List(viewModel.notifications) { notification in
                    ChildNotificationRow(notification: notification)
                }
                .listStyle(.insetGrouped)
                .refreshable { await viewModel.load() }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Nowości")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }
}

private struct ChildNotificationRow: View {
    let notification: NotificationDTO

    var body: some View {
        HStack(alignment: .top, spacing: BJSpacing.m) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: BJSpacing.xs) {
                Text(headline)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(color)
                Text(notification.message)
                    .font(.subheadline)
                    .fontWeight(notification.read ? .regular : .semibold)
                Text(Formatters.formatted(date: notification.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, BJSpacing.xs)
        .listRowBackground(notification.read ? Color(.secondarySystemGroupedBackground) : Color.bjMint)
    }

    private var headline: String {
        switch notification.type {
        case .taskCompleted: "Zadanie zgłoszone"
        case .taskApproved: "Brawo, zaliczone!"
        case .taskRejected: "Do poprawki"
        case .taskCancelled: "Zadanie odwołane"
        case .rewardPurchased: "Nagroda kupiona"
        case .rewardDelivered: "Nagroda czeka!"
        case .rewardReceived: "Nagroda odebrana"
        case .pointsAdjusted: "Zmiana punktów"
        case .childJoined: "Witaj w rodzinie!"
        case .childRemoved: "Do zobaczenia!"
        }
    }

    private var icon: String {
        switch notification.type {
        case .taskCompleted: "checkmark.circle"
        case .taskApproved: "checkmark.seal.fill"
        case .taskRejected: "arrow.uturn.backward.circle.fill"
        case .taskCancelled: "minus.circle.fill"
        case .rewardPurchased: "cart.fill"
        case .rewardDelivered: "gift.fill"
        case .rewardReceived: "hands.clap.fill"
        case .pointsAdjusted: "star.circle.fill"
        case .childJoined: "person.badge.plus"
        case .childRemoved: "person.badge.minus"
        }
    }

    private var color: Color {
        switch notification.type {
        case .taskCompleted: .blue
        case .taskApproved: .bjPrimary
        case .taskRejected: .bjDanger
        case .taskCancelled: .gray
        case .rewardPurchased: .bjAmber
        case .rewardDelivered: .purple
        case .rewardReceived: .bjPrimary
        case .pointsAdjusted: .bjAmber
        case .childJoined: .bjPrimary
        case .childRemoved: .gray
        }
    }
}
