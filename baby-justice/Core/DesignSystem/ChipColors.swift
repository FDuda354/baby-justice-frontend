import SwiftUI

extension TaskAvailability {
    var chipColor: Color {
        switch self {
        case .shared: .bjAccent
        case .assigned: .indigo
        }
    }
}

extension TaskRecurrence {
    var chipColor: Color {
        switch self {
        case .oneTime: .gray
        case .repeatable: .teal
        }
    }
}

extension TaskStatus {
    var chipColor: Color {
        switch self {
        case .active: .bjPrimary
        case .completed: .blue
        case .cancelled: .gray
        }
    }
}

extension AssignmentStatus {
    var chipColor: Color {
        switch self {
        case .inProgress: .blue
        case .pendingApproval: .bjAmber
        case .approved: .bjPrimary
        case .rejected: .bjDanger
        case .abandoned: .gray
        }
    }
}

extension PurchaseStatus {
    var chipColor: Color {
        switch self {
        case .pendingDelivery: .bjAmber
        case .delivered: .blue
        case .received: .bjPrimary
        case .cancelled: .gray
        }
    }
}
