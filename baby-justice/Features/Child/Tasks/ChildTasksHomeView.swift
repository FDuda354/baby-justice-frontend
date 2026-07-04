import SwiftUI

struct ChildTasksHomeView: View {
    @State private var viewModel = ChildTasksViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Picker("Widok zadań", selection: $viewModel.segment) {
                ForEach(ChildTasksSegment.allCases) { segment in
                    Text(segment.title).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, BJSpacing.l)
            .padding(.vertical, BJSpacing.s)
            content
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Zadania")
        .navigationDestination(for: TaskDTO.self) { task in
            ChildTaskDetailView(task: task, viewModel: viewModel)
        }
        .navigationDestination(for: TaskAssignmentDTO.self) { assignment in
            ChildAssignmentDetailView(assignment: assignment, viewModel: viewModel)
        }
        .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Ładowanie zadań...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(spacing: BJSpacing.m) {
                    if let message = viewModel.errorMessage {
                        ErrorBanner(message: message) {
                            Task { await viewModel.load() }
                        }
                    }
                    Group {
                        switch viewModel.segment {
                        case .available: availableList
                        case .mine: mineList
                        }
                    }
                    .padding(.horizontal, BJSpacing.l)
                }
                .padding(.vertical, BJSpacing.m)
            }
            .refreshable { await viewModel.load() }
        }
    }

    @ViewBuilder
    private var availableList: some View {
        if viewModel.availableTasks.isEmpty {
            EmptyStateView(
                icon: "checkmark.circle.fill",
                title: "Wszystko rozdane!",
                message: "Teraz nie ma zadań do wzięcia. Wpadnij tu później — na pewno coś się pojawi."
            )
        } else {
            ForEach(viewModel.availableTasks) { task in
                NavigationLink(value: task) {
                    AvailableTaskRow(task: task)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var mineList: some View {
        if viewModel.myTasks.isEmpty {
            EmptyStateView(
                icon: "figure.run",
                title: "Nic tu jeszcze nie ma",
                message: "Wybierz coś z listy \"Do wzięcia\" i zgarnij punkty!"
            )
        } else {
            ForEach(viewModel.myTasks) { assignment in
                if assignment.status == .inProgress {
                    NavigationLink(value: assignment) {
                        MyTaskRow(assignment: assignment)
                    }
                    .buttonStyle(.plain)
                } else {
                    MyTaskRow(assignment: assignment)
                }
            }
        }
    }
}

private struct AvailableTaskRow: View {
    let task: TaskDTO

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: BJSpacing.s) {
                HStack(alignment: .top) {
                    Text(task.name)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: BJSpacing.s)
                    PointsBadge(points: task.points)
                }
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: BJSpacing.s) {
                    if task.availability == .shared {
                        StatusChip(text: "Wspólne", color: .indigo)
                    }
                    if task.recurrence == .repeatable {
                        StatusChip(text: "Powtarzalne", color: .teal)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

private struct MyTaskRow: View {
    let assignment: TaskAssignmentDTO

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: BJSpacing.s) {
                HStack(alignment: .top) {
                    Text(assignment.taskName)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: BJSpacing.s)
                    PointsBadge(points: assignment.points)
                }
                HStack(spacing: BJSpacing.s) {
                    StatusChip(text: assignment.status.displayName, color: statusColor)
                    Spacer()
                    if assignment.status == .inProgress {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                }
                if assignment.status == .pendingApproval {
                    Label("Czeka na akceptację rodzica", systemImage: "hourglass")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var statusColor: Color {
        switch assignment.status {
        case .inProgress: .blue
        case .pendingApproval: .bjAmber
        case .approved: .bjPrimary
        case .rejected: .bjDanger
        case .abandoned: .gray
        }
    }
}
