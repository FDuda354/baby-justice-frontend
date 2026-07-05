import Foundation
import Observation

enum ChildTasksSegment: String, CaseIterable, Identifiable {
    case available
    case mine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .available: "Do wzięcia"
        case .mine: "Moje zadania"
        }
    }
}

@Observable
final class ChildTasksViewModel {
    var segment: ChildTasksSegment = .available
    var availableTasks: [AvailableTaskDTO] = []
    var myTasks: [TaskAssignmentDTO] = []
    var isLoading = false
    var errorMessage: String?
    var actionErrorMessage: String?
    var isPerformingAction = false

    private var hasLoaded = false
    private let loadFlight = SingleFlightTask()

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        await loadFlight.run { await self.fetchAll() }
    }

    private func fetchAll() async {
        isLoading = !hasLoaded
        errorMessage = nil
        do {
            async let availableCall = APIClient.shared.availableTasks()
            async let mineCall = APIClient.shared.myTasks()
            availableTasks = try await availableCall
            myTasks = try await mineCall
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func accept(_ task: AvailableTaskDTO) async -> Bool {
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            let assignment = try await APIClient.shared.acceptTask(taskId: task.id)
            availableTasks.removeAll { $0.id == task.id }
            myTasks.insert(assignment, at: 0)
            segment = .mine
            return true
        } catch {
            actionErrorMessage = acceptFailureMessage(for: error)
            await refreshQuietly()
            return false
        }
    }

    private func acceptFailureMessage(for error: Error) -> String {
        if case APIError.server(_, let status) = error, status == 409 {
            return "Ktoś już wziął to zadanie."
        }
        return error.localizedDescription
    }

    func complete(_ assignment: TaskAssignmentDTO) async -> Bool {
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            let updated = try await APIClient.shared.completeAssignment(assignmentId: assignment.id)
            if let index = myTasks.firstIndex(where: { $0.id == assignment.id }) {
                myTasks[index] = updated
            }
            return true
        } catch {
            actionErrorMessage = error.localizedDescription
            await refreshQuietly()
            return false
        }
    }

    func abandon(_ assignment: TaskAssignmentDTO) async -> Bool {
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            try await APIClient.shared.abandonAssignment(assignmentId: assignment.id)
            myTasks.removeAll { $0.id == assignment.id }
            await refreshQuietly()
            return true
        } catch {
            actionErrorMessage = error.localizedDescription
            await refreshQuietly()
            return false
        }
    }

    private func refreshQuietly() async {
        async let availableCall = APIClient.shared.availableTasks()
        async let mineCall = APIClient.shared.myTasks()
        if let tasks = try? await availableCall {
            availableTasks = tasks
        }
        if let assignments = try? await mineCall {
            myTasks = assignments
        }
    }
}
