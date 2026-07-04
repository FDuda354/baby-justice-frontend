import Foundation
import Observation

@Observable
final class ApprovalsViewModel {
    private(set) var approvals: [TaskAssignmentDTO] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var selectedAssignment: TaskAssignmentDTO?
    private var hasLoaded = false

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load(showLoading: Bool = true) async {
        if showLoading {
            isLoading = true
        }
        errorMessage = nil
        do {
            approvals = try await APIClient.shared.approvals()
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
