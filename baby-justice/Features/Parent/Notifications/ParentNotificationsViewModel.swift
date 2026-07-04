import Foundation
import Observation

@Observable
final class ParentNotificationsViewModel {
    var notifications: [NotificationDTO] = []
    var isLoading = false
    var errorMessage: String?

    func load() async {
        if notifications.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        do {
            let loaded = try await APIClient.shared.parentNotifications()
            notifications = loaded.sorted { $0.createdAt > $1.createdAt }
            isLoading = false
            await markAsReadIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func markAsReadIfNeeded() async {
        guard notifications.contains(where: { !$0.read }) else { return }
        try? await APIClient.shared.markParentNotificationsRead()
    }
}
