import Foundation
import Observation

@Observable
final class ParentSettingsViewModel {
    var family: FamilyDTO?
    var familyName = ""
    var isLoading = false
    var loadErrorMessage: String?
    var isSavingName = false
    var actionErrorMessage: String?

    var canSaveFamilyName: Bool {
        let trimmed = familyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != family?.name && !isSavingName
    }

    func loadIfNeeded() async {
        guard family == nil else { return }
        await load()
    }

    func load() async {
        isLoading = true
        loadErrorMessage = nil
        do {
            let loaded = try await APIClient.shared.family()
            family = loaded
            familyName = loaded.name
        } catch {
            loadErrorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveFamilyName() async {
        let trimmed = familyName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSavingName = true
        do {
            let updated = try await APIClient.shared.updateFamily(name: trimmed)
            family = updated
            familyName = updated.name
        } catch {
            actionErrorMessage = error.localizedDescription
        }
        isSavingName = false
    }
}
