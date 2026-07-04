import Foundation
import Observation

@Observable
final class ChildDashboardViewModel {
    var dashboard: ChildDashboardDTO?
    var isLoading = false
    var errorMessage: String?

    func loadIfNeeded() async {
        guard dashboard == nil else { return }
        await initialLoad()
    }

    func initialLoad() async {
        isLoading = true
        await fetch()
        isLoading = false
    }

    func refresh() async {
        await fetch()
    }

    private func fetch() async {
        do {
            dashboard = try await APIClient.shared.childDashboard()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
