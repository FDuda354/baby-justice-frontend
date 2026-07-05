import Foundation
import Observation

enum ParentHistorySegment: String, CaseIterable, Identifiable {
    case points
    case purchases
    case tasks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .points: "Punkty"
        case .purchases: "Zakupy"
        case .tasks: "Zadania"
        }
    }
}

@Observable
final class ParentHistoryViewModel {
    var segment: ParentHistorySegment = .points
    var selectedChildId: Int64?
    var children: [ChildDTO] = []
    var pointsHistory: [PointsTransactionDTO] = []
    var purchasesHistory: [RewardPurchaseDTO] = []
    var tasksHistory: [TaskAssignmentDTO] = []
    var isLoading = false
    var errorMessage: String?

    var selectedChildName: String {
        guard let id = selectedChildId, let child = children.first(where: { $0.id == id }) else {
            return "Wszystkie dzieci"
        }
        return child.name
    }

    func loadInitial() async {
        async let childrenLoad: Void = loadChildren()
        async let segmentLoad: Void = loadCurrentSegment()
        await childrenLoad
        await segmentLoad
    }

    func loadCurrentSegment() async {
        isLoading = true
        errorMessage = nil
        do {
            switch segment {
            case .points:
                pointsHistory = try await APIClient.shared.parentPointsHistory(childId: selectedChildId)
            case .purchases:
                purchasesHistory = try await APIClient.shared.parentPurchasesHistory(childId: selectedChildId)
            case .tasks:
                tasksHistory = try await APIClient.shared.parentTasksHistory(childId: selectedChildId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadChildren() async {
        guard children.isEmpty else { return }
        children = (try? await APIClient.shared.children()) ?? []
    }
}
