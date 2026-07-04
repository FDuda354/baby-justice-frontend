import Foundation
import Observation

@Observable
final class ParentTasksViewModel {
    enum TaskFilter: String, CaseIterable, Identifiable {
        case active
        case completed
        case cancelled
        case all

        var id: String { rawValue }

        var title: String {
            switch self {
            case .active: "Aktywne"
            case .completed: "Zakończone"
            case .cancelled: "Anulowane"
            case .all: "Wszystkie"
            }
        }

        var status: TaskStatus? {
            switch self {
            case .active: .active
            case .completed: .completed
            case .cancelled: .cancelled
            case .all: nil
            }
        }

        var emptyTitle: String {
            switch self {
            case .active: "Brak aktywnych zadań"
            case .completed: "Brak zakończonych zadań"
            case .cancelled: "Brak anulowanych zadań"
            case .all: "Brak zadań"
            }
        }

        var emptyMessage: String {
            switch self {
            case .active, .all: "Dodaj pierwsze zadanie przyciskiem plus w prawym górnym rogu."
            case .completed: "Zakończone zadania pojawią się tutaj po zatwierdzeniu."
            case .cancelled: "Anulowane zadania pojawią się tutaj."
            }
        }
    }

    var filter: TaskFilter = .active
    private(set) var tasks: [TaskDTO] = []
    private(set) var pendingApprovalsCount = 0
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?

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
            async let tasksCall = APIClient.shared.parentTasks(status: filter.status)
            async let approvalsCall = APIClient.shared.approvals()
            tasks = try await tasksCall
            pendingApprovalsCount = try await approvalsCall.count
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func refreshQuietly() async {
        guard hasLoaded, !isLoading else { return }
        await load(showLoading: false)
    }
}
