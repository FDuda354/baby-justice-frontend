import SwiftUI

struct ApprovalsView: View {
    @State private var model = ApprovalsViewModel()

    var body: some View {
        content
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Do akceptacji")
            .navigationBarTitleDisplayMode(.inline)
            .task { await model.loadIfNeeded() }
            .sheet(item: $model.selectedAssignment) { assignment in
                ApprovalDecisionView(assignment: assignment) {
                    Task { await model.load(showLoading: false) }
                }
                .presentationDetents([.medium, .large])
            }
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let message = model.errorMessage {
            ScrollView {
                ErrorBanner(message: message) {
                    Task { await model.load() }
                }
                .padding(.top, BJSpacing.l)
            }
        } else if model.approvals.isEmpty {
            emptyState
        } else {
            approvalsList
        }
    }

    private var emptyState: some View {
        ScrollView {
            EmptyStateView(
                icon: "checkmark.seal.fill",
                title: "Nic nie czeka na akceptację 🎉",
                message: "Gdy dziecko ukończy zadanie, pojawi się tutaj do zatwierdzenia."
            )
            .padding(.top, BJSpacing.xxl)
        }
        .refreshable { await model.load(showLoading: false) }
    }

    private var approvalsList: some View {
        ScrollView {
            LazyVStack(spacing: BJSpacing.m) {
                ForEach(model.approvals) { assignment in
                    Button {
                        model.selectedAssignment = assignment
                    } label: {
                        ApprovalRowView(assignment: assignment)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(BJSpacing.l)
        }
        .refreshable { await model.load(showLoading: false) }
    }
}

struct ApprovalRowView: View {
    let assignment: TaskAssignmentDTO

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: BJSpacing.s) {
                HStack(alignment: .top, spacing: BJSpacing.m) {
                    VStack(alignment: .leading, spacing: BJSpacing.xs) {
                        Text(assignment.taskName)
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                        Label(assignment.childName, systemImage: "person.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    PointsBadge(points: assignment.points)
                }
                if let completedAt = assignment.completedAt {
                    Text("Ukończono \(Formatters.formatted(date: completedAt))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
