import Foundation
import Observation

@Observable
final class ChildDetailsViewModel {
    let childId: Int64

    var child: ChildDTO?
    var activity: ChildActivityDTO?
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
            async let childCall = APIClient.shared.child(childId: childId)
            async let activityCall = APIClient.shared.childActivity(childId: childId)
            child = try await childCall
            activity = try await activityCall
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
            ParentBadgesStore.shared.refreshSoon()
            isDetaching = false
            return true
        } catch {
            actionError = error.localizedDescription
            isDetaching = false
            return false
        }
    }
}
