import Foundation
import Observation

@Observable
final class ParentDashboardViewModel {
    var dashboard: ParentDashboardDTO?
    var isLoading = false
    var errorMessage: String?

    func load() async {
        if dashboard == nil {
            isLoading = true
        }
        do {
            dashboard = try await APIClient.shared.parentDashboard()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
