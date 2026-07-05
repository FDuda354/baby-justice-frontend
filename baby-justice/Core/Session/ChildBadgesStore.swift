import Foundation
import Observation

@Observable
final class ChildBadgesStore {
    static let shared = ChildBadgesStore()

    private(set) var deliveredPurchasesCount = 0

    private init() {}

    func refresh() async {
        guard let dashboard = try? await APIClient.shared.childDashboard() else { return }
        deliveredPurchasesCount = dashboard.deliveredPurchasesCount
    }

    func refreshSoon() {
        Task { await refresh() }
    }
}
