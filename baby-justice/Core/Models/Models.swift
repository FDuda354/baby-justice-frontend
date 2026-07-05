import Foundation

enum Role: String, Codable, CaseIterable {
    case parent = "PARENT"
    case child = "CHILD"

    var displayName: String {
        switch self {
        case .parent: "Rodzic"
        case .child: "Dziecko"
        }
    }
}

enum TaskAvailability: String, Codable, CaseIterable {
    case shared = "SHARED"
    case assigned = "ASSIGNED"

    var displayName: String {
        switch self {
        case .shared: "Wspólne"
        case .assigned: "Przypisane"
        }
    }
}

enum TaskRecurrence: String, Codable, CaseIterable {
    case oneTime = "ONE_TIME"
    case repeatable = "REPEATABLE"

    var displayName: String {
        switch self {
        case .oneTime: "Jednorazowe"
        case .repeatable: "Powtarzalne"
        }
    }
}

enum TaskStatus: String, Codable, CaseIterable {
    case active = "ACTIVE"
    case completed = "COMPLETED"
    case cancelled = "CANCELLED"

    var displayName: String {
        switch self {
        case .active: "Aktywne"
        case .completed: "Zakończone"
        case .cancelled: "Anulowane"
        }
    }
}

enum AssignmentStatus: String, Codable, CaseIterable {
    case inProgress = "IN_PROGRESS"
    case pendingApproval = "PENDING_APPROVAL"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case abandoned = "ABANDONED"

    var displayName: String {
        switch self {
        case .inProgress: "W trakcie"
        case .pendingApproval: "Czeka na akceptację"
        case .approved: "Zaliczone"
        case .rejected: "Odrzucone"
        case .abandoned: "Porzucone"
        }
    }
}

enum RewardType: String, Codable, CaseIterable {
    case oneTime = "ONE_TIME"
    case repeatable = "REPEATABLE"

    var displayName: String {
        switch self {
        case .oneTime: "Jednorazowa"
        case .repeatable: "Powtarzalna"
        }
    }
}

enum RewardStatus: String, Codable, CaseIterable {
    case active = "ACTIVE"
    case purchased = "PURCHASED"
    case archived = "ARCHIVED"

    var displayName: String {
        switch self {
        case .active: "Aktywna"
        case .purchased: "Kupiona"
        case .archived: "Zarchiwizowana"
        }
    }
}

enum PurchaseStatus: String, Codable, CaseIterable {
    case pendingDelivery = "PENDING_DELIVERY"
    case delivered = "DELIVERED"
    case received = "RECEIVED"

    var displayName: String {
        switch self {
        case .pendingDelivery: "Do wydania"
        case .delivered: "Wydana — potwierdź odbiór"
        case .received: "Odebrana"
        }
    }
}

enum PointsTransactionType: String, Codable, CaseIterable {
    case taskReward = "TASK_REWARD"
    case manualAdjustment = "MANUAL_ADJUSTMENT"
    case purchase = "PURCHASE"

    var displayName: String {
        switch self {
        case .taskReward: "Nagroda za zadanie"
        case .manualAdjustment: "Korekta punktów"
        case .purchase: "Zakup nagrody"
        }
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case taskCompleted = "TASK_COMPLETED"
    case taskApproved = "TASK_APPROVED"
    case taskRejected = "TASK_REJECTED"
    case taskCancelled = "TASK_CANCELLED"
    case rewardPurchased = "REWARD_PURCHASED"
    case rewardDelivered = "REWARD_DELIVERED"
    case rewardReceived = "REWARD_RECEIVED"
    case pointsAdjusted = "POINTS_ADJUSTED"
    case childJoined = "CHILD_JOINED"
    case childRemoved = "CHILD_REMOVED"

    var displayName: String {
        switch self {
        case .taskCompleted: "Zadanie ukończone"
        case .taskApproved: "Zadanie zaliczone"
        case .taskRejected: "Zadanie odrzucone"
        case .taskCancelled: "Zadanie anulowane"
        case .rewardPurchased: "Nagroda kupiona"
        case .rewardDelivered: "Nagroda wydana"
        case .rewardReceived: "Nagroda odebrana"
        case .pointsAdjusted: "Zmiana punktów"
        case .childJoined: "Dziecko dołączyło"
        case .childRemoved: "Dziecko usunięte z rodziny"
        }
    }
}

struct AuthResponse: Codable, Hashable {
    let token: String
    let role: Role
    let accountId: Int64
    let familyId: Int64?
    let familyName: String?
    let displayName: String
    let childCode: String?
}

struct FamilyDTO: Codable, Hashable, Identifiable {
    let id: Int64
    let name: String
    let parentName: String
    let parentEmail: String
}

struct ChildDTO: Codable, Hashable, Identifiable {
    let id: Int64
    let name: String
    let birthDate: String
    let email: String
    let childCode: String
    let familyName: String?
    let pointsBalance: Int
    let hasAvatar: Bool
    let createdAt: Date
}

struct ChildSummaryDTO: Codable, Hashable, Identifiable {
    let id: Int64
    let name: String
    let pointsBalance: Int
    let hasAvatar: Bool
    let activeTasksCount: Int
    let pendingApprovalsCount: Int
    let pendingDeliveriesCount: Int
}

struct TaskDTO: Codable, Hashable, Identifiable {
    let id: Int64
    let name: String
    let description: String
    let points: Int
    let availability: TaskAvailability
    let assignedChildId: Int64?
    let assignedChildName: String?
    let recurrence: TaskRecurrence
    let status: TaskStatus
    let createdAt: Date
}

struct TaskAssignmentDTO: Codable, Hashable, Identifiable {
    let id: Int64
    let taskId: Int64
    let taskName: String
    let points: Int
    let childId: Int64
    let childName: String
    let status: AssignmentStatus
    let acceptedAt: Date
    let completedAt: Date?
    let resolvedAt: Date?
    let rejectionReason: String?
}

struct TaskDetailsDTO: Codable, Hashable {
    let task: TaskDTO
    let assignments: [TaskAssignmentDTO]
}

struct AvailableTaskDTO: Codable, Hashable, Identifiable {
    let id: Int64
    let name: String
    let description: String
    let points: Int
    let availability: TaskAvailability
    let recurrence: TaskRecurrence
    let inProgressByName: String?

    var isAcceptable: Bool { inProgressByName == nil }
}

struct ChildActivityDTO: Codable, Hashable {
    let activeAssignments: [TaskAssignmentDTO]
    let pendingDeliveries: [RewardPurchaseDTO]
}

struct RewardDTO: Codable, Hashable, Identifiable {
    let id: Int64
    let childId: Int64
    let name: String
    let description: String
    let costPoints: Int
    let rewardType: RewardType
    let status: RewardStatus
    let hasImage: Bool
    let createdAt: Date
}

struct RewardPurchaseDTO: Codable, Hashable, Identifiable {
    let id: Int64
    let rewardId: Int64
    let rewardName: String
    let childId: Int64
    let childName: String
    let costPoints: Int
    let status: PurchaseStatus
    let rewardHasImage: Bool
    let purchasedAt: Date
    let deliveredAt: Date?
    let receivedAt: Date?
}

struct PointsTransactionDTO: Codable, Hashable, Identifiable {
    let id: Int64
    let childId: Int64
    let childName: String
    let delta: Int
    let balanceAfter: Int
    let type: PointsTransactionType
    let description: String
    let createdAt: Date
}

struct NotificationDTO: Codable, Hashable, Identifiable {
    let id: Int64
    let type: NotificationType
    let message: String
    let read: Bool
    let createdAt: Date
}

struct ParentDashboardDTO: Codable, Hashable {
    let familyName: String
    let pendingApprovalsCount: Int
    let pendingDeliveriesCount: Int
    let unreadNotificationsCount: Int
    let children: [ChildSummaryDTO]
}

struct ChildDashboardDTO: Codable, Hashable {
    let name: String
    let pointsBalance: Int
    let hasAvatar: Bool
    let hasFamily: Bool
    let familyName: String?
    let childCode: String
    let availableTasksCount: Int
    let activeTasksCount: Int
    let pendingApprovalsCount: Int
    let deliveredPurchasesCount: Int
    let unreadNotificationsCount: Int
    let recentTransactions: [PointsTransactionDTO]
}
