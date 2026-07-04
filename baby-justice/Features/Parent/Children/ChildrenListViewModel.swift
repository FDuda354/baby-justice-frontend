import Foundation
import Observation

@Observable
final class ChildrenListViewModel {
    var children: [ChildDTO] = []
    var isLoading = false
    var errorMessage: String?
    var hasLoaded = false

    func load() async {
        if !hasLoaded {
            isLoading = true
        }
        do {
            children = try await APIClient.shared.children()
            errorMessage = nil
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
