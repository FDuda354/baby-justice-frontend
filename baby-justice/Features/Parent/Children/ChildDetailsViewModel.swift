import Foundation
import Observation

@Observable
final class ChildDetailsViewModel {
    let childId: Int64

    var child: ChildDTO?
    var isLoading = false
    var errorMessage: String?
    var actionError: String?
    var isDetaching = false

    init(childId: Int64) {
        self.childId = childId
    }

    func load() async {
        if child == nil {
            isLoading = true
        }
        do {
            child = try await APIClient.shared.child(childId: childId)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func detachChild() async -> Bool {
        actionError = nil
        isDetaching = true
        do {
            try await APIClient.shared.detachChild(childId: childId)
            isDetaching = false
            return true
        } catch {
            actionError = error.localizedDescription
            isDetaching = false
            return false
        }
    }
}
