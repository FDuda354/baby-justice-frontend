import Foundation
import Observation

@Observable
final class ChildHistoryViewModel {
    var pointsHistory: [PointsTransactionDTO] = []
    var tasksHistory: [TaskAssignmentDTO] = []
    var isLoading = false
    var errorMessage: String?

    var isEmpty: Bool {
        pointsHistory.isEmpty && tasksHistory.isEmpty
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let points = APIClient.shared.childPointsHistory()
            async let tasks = APIClient.shared.childTasksHistory()
            pointsHistory = try await points
            tasksHistory = try await tasks
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
