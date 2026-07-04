import SwiftUI

private enum ChildHistorySegment: String, CaseIterable, Identifiable {
    case points = "Punkty"
    case tasks = "Zadania"

    var id: String { rawValue }
}

struct ChildHistoryHomeView: View {
    @State private var viewModel = ChildHistoryViewModel()
    @State private var segment = ChildHistorySegment.points

    var body: some View {
        VStack(spacing: 0) {
            segmentPicker
            content
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Historia")
        .task { await viewModel.load() }
    }

    private var segmentPicker: some View {
        Picker("Widok", selection: $segment) {
            ForEach(ChildHistorySegment.allCases) { segment in
                Text(segment.rawValue).tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, BJSpacing.l)
        .padding(.vertical, BJSpacing.s)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.isEmpty {
            loadingState
        } else if let message = viewModel.errorMessage, viewModel.isEmpty {
            errorState(message: message)
        } else {
            historyList
        }
    }

    private var loadingState: some View {
        VStack {
            Spacer()
            ProgressView("Ładowanie historii…")
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func errorState(message: String) -> some View {
        VStack {
            ErrorBanner(message: message) {
                Task { await viewModel.load() }
            }
            Spacer()
        }
        .padding(.top, BJSpacing.l)
    }

    private var historyList: some View {
        ScrollView {
            VStack(spacing: BJSpacing.m) {
                if let message = viewModel.errorMessage {
                    ErrorBanner(message: message) {
                        Task { await viewModel.load() }
                    }
                }
                segmentContent
                    .padding(.horizontal, BJSpacing.l)
            }
            .padding(.vertical, BJSpacing.s)
            .padding(.bottom, BJSpacing.xl)
        }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var segmentContent: some View {
        switch segment {
        case .points:
            pointsContent
        case .tasks:
            tasksContent
        }
    }

    @ViewBuilder
    private var pointsContent: some View {
        if viewModel.pointsHistory.isEmpty {
            EmptyStateView(
                icon: "star.circle.fill",
                title: "Brak historii punktów",
                message: "Wykonuj zadania i zbieraj punkty — każda zmiana pojawi się tutaj!"
            )
            .padding(.top, BJSpacing.xl)
        } else {
            VStack(spacing: BJSpacing.m) {
                ForEach(viewModel.pointsHistory) { transaction in
                    ChildPointsHistoryRow(transaction: transaction)
                }
            }
        }
    }

    @ViewBuilder
    private var tasksContent: some View {
        if viewModel.tasksHistory.isEmpty {
            EmptyStateView(
                icon: "checklist",
                title: "Brak zakończonych zadań",
                message: "Gdy rodzic oceni Twoje zadania, zobaczysz je tutaj. Do dzieła!"
            )
            .padding(.top, BJSpacing.xl)
        } else {
            VStack(spacing: BJSpacing.m) {
                ForEach(viewModel.tasksHistory) { assignment in
                    ChildTaskHistoryRow(assignment: assignment)
                }
            }
        }
    }
}

private struct ChildPointsHistoryRow: View {
    let transaction: PointsTransactionDTO

    var body: some View {
        CardView {
            HStack(alignment: .top, spacing: BJSpacing.m) {
                VStack(alignment: .leading, spacing: BJSpacing.xs) {
                    Text(transaction.description)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(Formatters.formatted(date: transaction.createdAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: BJSpacing.xs) {
                    Text("\(Formatters.signedPoints(transaction.delta)) pkt")
                        .font(.headline)
                        .foregroundStyle(deltaColor)
                    Text("Saldo: \(transaction.balanceAfter) pkt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var deltaColor: Color {
        transaction.delta >= 0 ? .bjPrimary : .bjDanger
    }
}

private struct ChildTaskHistoryRow: View {
    let assignment: TaskAssignmentDTO

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: BJSpacing.s) {
                HStack(alignment: .top) {
                    Text(assignment.taskName)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Spacer()
                    PointsBadge(points: assignment.points)
                        .font(.subheadline)
                }
                HStack {
                    StatusChip(text: assignment.status.displayName, color: statusColor)
                    Spacer()
                    Text(Formatters.formatted(date: resolvedDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let reason = assignment.rejectionReason, !reason.isEmpty {
                    Text("Powód odrzucenia: \(reason)")
                        .font(.caption)
                        .foregroundStyle(Color.bjDanger)
                }
            }
        }
    }

    private var resolvedDate: Date {
        assignment.resolvedAt ?? assignment.completedAt ?? assignment.acceptedAt
    }

    private var statusColor: Color {
        switch assignment.status {
        case .approved: .bjPrimary
        case .rejected: .bjDanger
        case .abandoned: .gray
        case .inProgress: .blue
        case .pendingApproval: .bjAmber
        }
    }
}
