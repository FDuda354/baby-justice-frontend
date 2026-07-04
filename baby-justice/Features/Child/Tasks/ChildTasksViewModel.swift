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
    var availableTasks: [TaskDTO] = []
    var myTasks: [TaskAssignmentDTO] = []
    var isLoading = false
    var errorMessage: String?
    var actionErrorMessage: String?
    var isPerformingAction = false

    private var hasLoaded = false

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        isLoading = !hasLoaded
        errorMessage = nil
        do {
            availableTasks = try await APIClient.shared.availableTasks()
            myTasks = try await APIClient.shared.myTasks()
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func accept(_ task: TaskDTO) async -> Bool {
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            let assignment = try await APIClient.shared.acceptTask(taskId: task.id)
            availableTasks.removeAll { $0.id == task.id }
            myTasks.insert(assignment, at: 0)
            segment = .mine
            return true
        } catch {
            actionErrorMessage = error.localizedDescription
            await refreshQuietly()
            return false
        }
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
        if let tasks = try? await APIClient.shared.availableTasks() {
            availableTasks = tasks
        }
        if let assignments = try? await APIClient.shared.myTasks() {
            myTasks = assignments
        }
    }
}
