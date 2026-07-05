import Foundation
import Observation

@Observable
final class ParentBadgesStore {
    static let shared = ParentBadgesStore()

    private(set) var pendingApprovalsCount = 0
    private(set) var pendingDeliveriesCount = 0
    private(set) var unreadNotificationsCount = 0

    private init() {}

    func refresh() async {
        guard let dashboard = try? await APIClient.shared.parentDashboard() else { return }
        pendingApprovalsCount = dashboard.pendingApprovalsCount
        pendingDeliveriesCount = dashboard.pendingDeliveriesCount
        unreadNotificationsCount = dashboard.unreadNotificationsCount
    }

    func refreshSoon() {
        Task { await refresh() }
    }
}
