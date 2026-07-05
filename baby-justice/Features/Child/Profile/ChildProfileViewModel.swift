import Foundation
import Observation

@Observable
final class ChildProfileViewModel {
    var profile: ChildDTO?
    var isLoading = false
    var errorMessage: String?
    var actionError: String?
    var infoMessage: String?
    var isProcessingAvatar = false
    var avatarVersion = 0
    private let loadFlight = SingleFlightTask()

    func load() async {
        await loadFlight.run { await self.fetchProfile() }
    }

    private func fetchProfile() async {
        if profile == nil {
            isLoading = true
        }
        do {
            profile = try await APIClient.shared.childProfile()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func uploadAvatar(imageData: Data) async {
        clearFeedback()
        guard let jpegData = AvatarImageProcessor.downscaledJpegData(from: imageData) else {
            actionError = "Nie udało się przetworzyć wybranego zdjęcia. Spróbuj z innym."
            return
        }
        isProcessingAvatar = true
        do {
            try await APIClient.shared.uploadChildAvatar(base64: jpegData.base64EncodedString(), contentType: "image/jpeg")
            profile = try await APIClient.shared.childProfile()
            avatarVersion += 1
            infoMessage = "Zdjęcie zostało zaktualizowane."
        } catch {
            actionError = error.localizedDescription
        }
        isProcessingAvatar = false
    }

    func removeAvatar() async {
        clearFeedback()
        isProcessingAvatar = true
        do {
            try await APIClient.shared.deleteChildAvatar()
            profile = try await APIClient.shared.childProfile()
            avatarVersion += 1
            infoMessage = "Zdjęcie zostało usunięte."
        } catch {
            actionError = error.localizedDescription
        }
        isProcessingAvatar = false
    }

    func clearFeedback() {
        actionError = nil
        infoMessage = nil
    }
}
