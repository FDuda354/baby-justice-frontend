import Foundation

struct ParentRegisterRequest: Encodable {
    let familyName: String
    let parentName: String
    let email: String
    let password: String
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct ChildRegisterRequest: Encodable {
    let name: String
    let birthDate: String
    let email: String
    let password: String
}

struct PasswordResetRequest: Encodable {
    let email: String
}

struct PasswordResetConfirmRequest: Encodable {
    let token: String
    let newPassword: String
}

struct UpdateFamilyRequest: Encodable {
    let name: String
}

struct ChangePasswordRequest: Encodable {
    let currentPassword: String
    let newPassword: String
}

struct AddChildRequest: Encodable {
    let childCode: String
}

struct DeleteAccountRequest: Encodable {
    let password: String
}

struct ImageUploadRequest: Encodable {
    let imageBase64: String
    let contentType: String
}

struct AdjustPointsRequest: Encodable {
    let delta: Int
    let description: String
}

struct CreateTaskRequest: Encodable {
    let name: String
    let description: String
    let points: Int
    let availability: TaskAvailability
    let assignedChildId: Int64?
    let recurrence: TaskRecurrence
}

struct RejectAssignmentRequest: Encodable {
    let reason: String
}

struct CreateRewardRequest: Encodable {
    let name: String
    let description: String
    let costPoints: Int
    let rewardType: RewardType
    let imageBase64: String?
    let imageContentType: String?
    let removeImage: Bool?
}

struct PurchaseRewardRequest: Encodable {
    let purchaseToken: String
}

final class APIClient {
    static let shared = APIClient()

    private let urlSession: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        urlSession = URLSession.shared
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try await request(method: "POST", path: "/api/auth/login", body: LoginRequest(email: email, password: password))
    }

    func registerParent(familyName: String, parentName: String, email: String, password: String) async throws -> AuthResponse {
        try await request(method: "POST", path: "/api/auth/parent/register", body: ParentRegisterRequest(familyName: familyName, parentName: parentName, email: email, password: password))
    }

    func registerChild(name: String, birthDate: String, email: String, password: String) async throws -> AuthResponse {
        try await request(method: "POST", path: "/api/auth/child/register", body: ChildRegisterRequest(name: name, birthDate: birthDate, email: email, password: password))
    }

    func requestPasswordReset(email: String) async throws {
        try await requestVoid(method: "POST", path: "/api/auth/password-reset/request", body: PasswordResetRequest(email: email))
    }

    func confirmPasswordReset(token: String, newPassword: String) async throws {
        try await requestVoid(method: "POST", path: "/api/auth/password-reset/confirm", body: PasswordResetConfirmRequest(token: token, newPassword: newPassword))
    }

    func parentDashboard() async throws -> ParentDashboardDTO {
        try await request(method: "GET", path: "/api/parent/dashboard")
    }

    func family() async throws -> FamilyDTO {
        try await request(method: "GET", path: "/api/parent/family")
    }

    func updateFamily(name: String) async throws -> FamilyDTO {
        try await request(method: "PUT", path: "/api/parent/family", body: UpdateFamilyRequest(name: name))
    }

    func changeParentPassword(currentPassword: String, newPassword: String) async throws {
        try await requestVoid(method: "PUT", path: "/api/parent/account/password", body: ChangePasswordRequest(currentPassword: currentPassword, newPassword: newPassword), passwordVerifying: true)
    }

    func deleteParentAccount(password: String) async throws {
        try await requestVoid(method: "POST", path: "/api/parent/account/delete", body: DeleteAccountRequest(password: password), passwordVerifying: true)
    }

    func children() async throws -> [ChildDTO] {
        try await request(method: "GET", path: "/api/parent/children")
    }

    func addChildByCode(_ childCode: String) async throws -> ChildDTO {
        try await request(method: "POST", path: "/api/parent/children", body: AddChildRequest(childCode: childCode))
    }

    func child(childId: Int64) async throws -> ChildDTO {
        try await request(method: "GET", path: "/api/parent/children/\(childId)")
    }

    func detachChild(childId: Int64) async throws {
        try await requestVoid(method: "DELETE", path: "/api/parent/children/\(childId)")
    }

    func adjustChildPoints(childId: Int64, delta: Int, description: String) async throws -> ChildDTO {
        try await request(method: "POST", path: "/api/parent/children/\(childId)/points", body: AdjustPointsRequest(delta: delta, description: description))
    }

    func childActivity(childId: Int64) async throws -> ChildActivityDTO {
        try await request(method: "GET", path: "/api/parent/children/\(childId)/activity")
    }

    func parentTasks(status: TaskStatus? = nil) async throws -> [TaskDTO] {
        let query = status.map { [URLQueryItem(name: "status", value: $0.rawValue)] } ?? []
        return try await request(method: "GET", path: "/api/parent/tasks", query: query)
    }

    func createTask(_ body: CreateTaskRequest) async throws -> TaskDTO {
        try await request(method: "POST", path: "/api/parent/tasks", body: body)
    }

    func taskDetails(taskId: Int64) async throws -> TaskDetailsDTO {
        try await request(method: "GET", path: "/api/parent/tasks/\(taskId)")
    }

    func updateTask(taskId: Int64, _ body: CreateTaskRequest) async throws -> TaskDTO {
        try await request(method: "PUT", path: "/api/parent/tasks/\(taskId)", body: body)
    }

    func cancelTask(taskId: Int64) async throws {
        try await requestVoid(method: "POST", path: "/api/parent/tasks/\(taskId)/cancel")
    }

    func approvals() async throws -> [TaskAssignmentDTO] {
        try await request(method: "GET", path: "/api/parent/approvals")
    }

    func approveAssignment(assignmentId: Int64) async throws {
        try await requestVoid(method: "POST", path: "/api/parent/approvals/\(assignmentId)/approve")
    }

    func rejectAssignment(assignmentId: Int64, reason: String) async throws {
        try await requestVoid(method: "POST", path: "/api/parent/approvals/\(assignmentId)/reject", body: RejectAssignmentRequest(reason: reason))
    }

    func rewards(childId: Int64, includeArchived: Bool = false) async throws -> [RewardDTO] {
        let query = [URLQueryItem(name: "includeArchived", value: includeArchived ? "true" : "false")]
        return try await request(method: "GET", path: "/api/parent/children/\(childId)/rewards", query: query)
    }

    func createReward(childId: Int64, _ body: CreateRewardRequest) async throws -> RewardDTO {
        try await request(method: "POST", path: "/api/parent/children/\(childId)/rewards", body: body)
    }

    func reward(rewardId: Int64) async throws -> RewardDTO {
        try await request(method: "GET", path: "/api/parent/rewards/\(rewardId)")
    }

    func updateReward(rewardId: Int64, _ body: CreateRewardRequest) async throws -> RewardDTO {
        let updated: RewardDTO = try await request(method: "PUT", path: "/api/parent/rewards/\(rewardId)", body: body)
        ImageCache.shared.removeImage(for: "/api/images/rewards/\(rewardId)")
        return updated
    }

    func archiveReward(rewardId: Int64) async throws {
        try await requestVoid(method: "POST", path: "/api/parent/rewards/\(rewardId)/archive")
    }

    func deliveries() async throws -> [RewardPurchaseDTO] {
        try await request(method: "GET", path: "/api/parent/deliveries")
    }

    func markDelivered(purchaseId: Int64) async throws {
        try await requestVoid(method: "POST", path: "/api/parent/deliveries/\(purchaseId)/deliver")
    }

    func parentPointsHistory(childId: Int64? = nil) async throws -> [PointsTransactionDTO] {
        try await request(method: "GET", path: "/api/parent/history/points", query: childIdQuery(childId))
    }

    func parentPurchasesHistory(childId: Int64? = nil) async throws -> [RewardPurchaseDTO] {
        try await request(method: "GET", path: "/api/parent/history/purchases", query: childIdQuery(childId))
    }

    func parentTasksHistory(childId: Int64? = nil) async throws -> [TaskAssignmentDTO] {
        try await request(method: "GET", path: "/api/parent/history/tasks", query: childIdQuery(childId))
    }

    func parentNotifications() async throws -> [NotificationDTO] {
        try await request(method: "GET", path: "/api/parent/notifications")
    }

    func markParentNotificationsRead() async throws {
        try await requestVoid(method: "POST", path: "/api/parent/notifications/mark-read")
    }

    func childDashboard() async throws -> ChildDashboardDTO {
        try await request(method: "GET", path: "/api/child/dashboard")
    }

    func childProfile() async throws -> ChildDTO {
        try await request(method: "GET", path: "/api/child/profile")
    }

    func changeChildPassword(current: String, new: String) async throws {
        try await requestVoid(method: "PUT", path: "/api/child/account/password", body: ChangePasswordRequest(currentPassword: current, newPassword: new), passwordVerifying: true)
    }

    func deleteChildAccount(password: String) async throws {
        try await requestVoid(method: "POST", path: "/api/child/account/delete", body: DeleteAccountRequest(password: password), passwordVerifying: true)
    }

    func uploadChildAvatar(base64: String, contentType: String) async throws {
        try await requestVoid(method: "PUT", path: "/api/child/avatar", body: ImageUploadRequest(imageBase64: base64, contentType: contentType))
        invalidateOwnAvatarImage()
    }

    func deleteChildAvatar() async throws {
        try await requestVoid(method: "DELETE", path: "/api/child/avatar")
        invalidateOwnAvatarImage()
    }

    private func invalidateOwnAvatarImage() {
        guard let childId = SessionStore.shared.accountId else { return }
        ImageCache.shared.removeImage(for: "/api/images/children/\(childId)/avatar")
    }

    func availableTasks() async throws -> [AvailableTaskDTO] {
        try await request(method: "GET", path: "/api/child/tasks/available")
    }

    func acceptTask(taskId: Int64) async throws -> TaskAssignmentDTO {
        try await request(method: "POST", path: "/api/child/tasks/\(taskId)/accept")
    }

    func myTasks() async throws -> [TaskAssignmentDTO] {
        try await request(method: "GET", path: "/api/child/tasks/mine")
    }

    func completeAssignment(assignmentId: Int64) async throws -> TaskAssignmentDTO {
        try await request(method: "POST", path: "/api/child/assignments/\(assignmentId)/complete")
    }

    func abandonAssignment(assignmentId: Int64) async throws {
        try await requestVoid(method: "POST", path: "/api/child/assignments/\(assignmentId)/abandon")
    }

    func shopRewards() async throws -> [RewardDTO] {
        try await request(method: "GET", path: "/api/child/rewards")
    }

    func purchaseReward(rewardId: Int64, purchaseToken: String) async throws -> RewardPurchaseDTO {
        try await request(method: "POST", path: "/api/child/rewards/\(rewardId)/purchase", body: PurchaseRewardRequest(purchaseToken: purchaseToken))
    }

    func myPurchases() async throws -> [RewardPurchaseDTO] {
        try await request(method: "GET", path: "/api/child/purchases")
    }

    func confirmReceipt(purchaseId: Int64) async throws -> RewardPurchaseDTO {
        try await request(method: "POST", path: "/api/child/purchases/\(purchaseId)/confirm-receipt")
    }

    func childPointsHistory() async throws -> [PointsTransactionDTO] {
        try await request(method: "GET", path: "/api/child/history/points")
    }

    func childTasksHistory() async throws -> [TaskAssignmentDTO] {
        try await request(method: "GET", path: "/api/child/history/tasks")
    }

    func childNotifications() async throws -> [NotificationDTO] {
        try await request(method: "GET", path: "/api/child/notifications")
    }

    func markChildNotificationsRead() async throws {
        try await requestVoid(method: "POST", path: "/api/child/notifications/mark-read")
    }

    func fetchImage(path: String) async -> Data? {
        guard let url = try? makeURL(path: path, query: []) else { return nil }
        var urlRequest = URLRequest(url: url)
        attachAuthorization(to: &urlRequest)
        guard let (data, response) = try? await urlSession.data(for: urlRequest),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode)
        else { return nil }
        return data
    }

    private func childIdQuery(_ childId: Int64?) -> [URLQueryItem] {
        childId.map { [URLQueryItem(name: "childId", value: String($0))] } ?? []
    }

    private func request<T: Decodable>(method: String, path: String, query: [URLQueryItem] = [], body: (any Encodable)? = nil, passwordVerifying: Bool = false) async throws -> T {
        let data = try await perform(method: method, path: path, query: query, body: body, passwordVerifying: passwordVerifying)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    private func requestVoid(method: String, path: String, query: [URLQueryItem] = [], body: (any Encodable)? = nil, passwordVerifying: Bool = false) async throws {
        _ = try await perform(method: method, path: path, query: query, body: body, passwordVerifying: passwordVerifying)
    }

    private func perform(method: String, path: String, query: [URLQueryItem], body: (any Encodable)?, passwordVerifying: Bool) async throws -> Data {
        let url = try makeURL(path: path, query: query)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        let isAuthenticated = attachAuthorization(to: &urlRequest)
        if let body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                urlRequest.httpBody = try encoder.encode(body)
            } catch {
                throw APIError.decoding
            }
        }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: urlRequest)
        } catch {
            throw APIError.network
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.network
        }
        guard (200...299).contains(http.statusCode) else {
            throw errorForFailure(status: http.statusCode, data: data, passwordVerifying: passwordVerifying, isAuthenticated: isAuthenticated)
        }
        return data
    }

    private func errorForFailure(status: Int, data: Data, passwordVerifying: Bool, isAuthenticated: Bool) -> APIError {
        if status == 401 {
            if passwordVerifying {
                return .invalidPassword
            }
            if isAuthenticated {
                SessionStore.shared.logout()
            }
            return .unauthorized
        }
        if let body = try? decoder.decode(ApiErrorBody.self, from: data) {
            return .server(message: body.message, status: body.statusCode)
        }
        return .server(message: "Wystąpił nieoczekiwany błąd serwera.", status: status)
    }

    private func makeURL(path: String, query: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(url: AppConfig.baseURL, resolvingAgainstBaseURL: false) else {
            throw APIError.network
        }
        components.path = path
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else {
            throw APIError.network
        }
        return url
    }

    @discardableResult
    private func attachAuthorization(to urlRequest: inout URLRequest) -> Bool {
        guard let token = SessionStore.shared.token else { return false }
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return true
    }
}
