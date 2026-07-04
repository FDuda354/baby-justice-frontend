import SwiftUI

struct ParentNotificationsView: View {
    @State private var viewModel = ParentNotificationsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Wczytywanie…")
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
                        title: "Brak powiadomień",
                        message: "Gdy w Twojej rodzinie coś się wydarzy, zobaczysz to tutaj."
                    )
                }
                .refreshable { await viewModel.load() }
            } else {
                List(viewModel.notifications) { notification in
                    NotificationRow(notification: notification)
                }
                .listStyle(.insetGrouped)
                .refreshable { await viewModel.load() }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Powiadomienia")
        .task {
            await viewModel.load()
        }
    }
}

private struct NotificationRow: View {
    let notification: NotificationDTO

    var body: some View {
        HStack(alignment: .top, spacing: BJSpacing.m) {
            Image(systemName: notificationIcon(notification.type))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(notificationColor(notification.type))
                .frame(width: 36, height: 36)
                .background(notificationColor(notification.type).opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: BJSpacing.xs) {
                Text(notification.message)
                    .font(.subheadline)
                    .fontWeight(notification.read ? .regular : .bold)
                Text(Formatters.formatted(date: notification.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, BJSpacing.xs)
        .listRowBackground(notification.read ? Color(.secondarySystemGroupedBackground) : Color.bjMint)
    }
}

private func notificationIcon(_ type: NotificationType) -> String {
    switch type {
    case .taskCompleted: "checkmark.circle"
    case .taskApproved: "checkmark.seal.fill"
    case .taskRejected: "xmark.circle.fill"
    case .taskCancelled: "minus.circle.fill"
    case .rewardPurchased: "cart.fill"
    case .rewardDelivered: "shippingbox.fill"
    case .rewardReceived: "gift.fill"
    case .pointsAdjusted: "star.circle.fill"
    case .childJoined: "person.badge.plus"
    case .childRemoved: "person.badge.minus"
    }
}

private func notificationColor(_ type: NotificationType) -> Color {
    switch type {
    case .taskCompleted: .blue
    case .taskApproved: .bjPrimary
    case .taskRejected: .bjDanger
    case .taskCancelled: .gray
    case .rewardPurchased: .bjAmber
    case .rewardDelivered: .blue
    case .rewardReceived: .bjPrimary
    case .pointsAdjusted: .bjAmber
    case .childJoined: .bjPrimary
    case .childRemoved: .gray
    }
}
