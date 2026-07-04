import Foundation
import Observation

@Observable
final class TaskDetailsViewModel {
    let taskId: Int64

    private(set) var details: TaskDetailsDTO?
    private(set) var isLoading = false
    private(set) var isCancelling = false
    private(set) var errorMessage: String?
    var cancelErrorMessage: String?
    var showEditSheet = false
    var showCancelConfirmation = false
    private var hasLoaded = false

    init(taskId: Int64) {
        self.taskId = taskId
    }

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
            details = try await APIClient.shared.taskDetails(taskId: taskId)
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func cancelTask() async {
        isCancelling = true
        do {
            try await APIClient.shared.cancelTask(taskId: taskId)
            await load(showLoading: false)
        } catch {
            cancelErrorMessage = error.localizedDescription
        }
        isCancelling = false
    }
}
