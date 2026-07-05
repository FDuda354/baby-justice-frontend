import Foundation
import Observation

@Observable
final class ChildHistoryViewModel {
    var pointsHistory: [PointsTransactionDTO] = []
    var tasksHistory: [TaskAssignmentDTO] = []
    var isLoading = false
    var errorMessage: String?
    private var hasLoaded = false
    private let loadFlight = SingleFlightTask()

    var isEmpty: Bool {
        pointsHistory.isEmpty && tasksHistory.isEmpty
    }

    func load() async {
        await loadFlight.run { await self.fetch() }
    }

    private func fetch() async {
        isLoading = !hasLoaded
        errorMessage = nil
        do {
            async let points = APIClient.shared.childPointsHistory()
            async let tasks = APIClient.shared.childTasksHistory()
            pointsHistory = try await points
            tasksHistory = try await tasks
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
