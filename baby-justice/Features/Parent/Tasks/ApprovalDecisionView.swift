import SwiftUI
import Observation

@Observable
final class ApprovalDecisionViewModel {
    let assignment: TaskAssignmentDTO
    var rejectionReason = ""
    var showRejectionField = false
    private(set) var isApproving = false
    private(set) var isRejecting = false
    private(set) var errorMessage: String?

    init(assignment: TaskAssignmentDTO) {
        self.assignment = assignment
    }

    var trimmedReason: String {
        rejectionReason.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canReject: Bool {
        !trimmedReason.isEmpty && !isRejecting && !isApproving
    }

    func approve() async -> Bool {
        isApproving = true
        errorMessage = nil
        do {
            try await APIClient.shared.approveAssignment(assignmentId: assignment.id)
            isApproving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isApproving = false
            return false
        }
    }

    func reject() async -> Bool {
        isRejecting = true
        errorMessage = nil
        do {
            try await APIClient.shared.rejectAssignment(assignmentId: assignment.id, reason: trimmedReason)
            isRejecting = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isRejecting = false
            return false
        }
    }
}

struct ApprovalDecisionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: ApprovalDecisionViewModel
    private let onDecided: () -> Void

    init(assignment: TaskAssignmentDTO, onDecided: @escaping () -> Void) {
        _model = State(initialValue: ApprovalDecisionViewModel(assignment: assignment))
        self.onDecided = onDecided
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: BJSpacing.xl) {
                    summary
                    if let message = model.errorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(Color.bjDanger)
                            .multilineTextAlignment(.center)
                    }
                    decisionButtons
                }
                .padding(BJSpacing.l)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Akceptacja zadania")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zamknij") { dismiss() }
                }
            }
        }
    }

    private var summary: some View {
        VStack(spacing: BJSpacing.m) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.bjPrimary)
            Text(model.assignment.taskName)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Label(model.assignment.childName, systemImage: "person.fill")
                .font(.headline)
                .foregroundStyle(.secondary)
            PointsBadge(points: model.assignment.points)
                .font(.title2)
            if let completedAt = model.assignment.completedAt {
                Text("Ukończono \(Formatters.formatted(date: completedAt))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, BJSpacing.l)
    }

    private var decisionButtons: some View {
        VStack(spacing: BJSpacing.m) {
            PrimaryButton(title: "Zatwierdź (+\(model.assignment.points) pkt)", isLoading: model.isApproving) {
                Task {
                    if await model.approve() {
                        onDecided()
                        dismiss()
                    }
                }
            }
            .disabled(model.isRejecting)
            if model.showRejectionField {
                rejectionSection
            } else {
                Button {
                    model.showRejectionField = true
                } label: {
                    Text("Odrzuć")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: BJSize.buttonHeight)
                        .background(Color.bjDanger.opacity(0.12))
                        .foregroundStyle(Color.bjDanger)
                        .clipShape(RoundedRectangle(cornerRadius: BJRadius.button, style: .continuous))
                }
            }
        }
    }

    private var rejectionSection: some View {
        VStack(alignment: .leading, spacing: BJSpacing.m) {
            FormTextField(label: "Powód odrzucenia", text: $model.rejectionReason)
            Button {
                Task {
                    if await model.reject() {
                        onDecided()
                        dismiss()
                    }
                }
            } label: {
                ZStack {
                    if model.isRejecting {
                        ProgressView()
                            .tint(Color.bjDanger)
                    } else {
                        Text("Odrzuć zadanie")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: BJSize.buttonHeight)
                .background(Color.bjDanger.opacity(0.12))
                .foregroundStyle(Color.bjDanger)
                .clipShape(RoundedRectangle(cornerRadius: BJRadius.button, style: .continuous))
            }
            .disabled(!model.canReject)
            .opacity(model.canReject ? 1 : 0.5)
        }
    }
}
