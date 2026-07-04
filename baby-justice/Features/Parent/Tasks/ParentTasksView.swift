import SwiftUI

struct ParentTasksView: View {
    @State private var model = ParentTasksViewModel()
    @State private var showAddTask = false

    var body: some View {
        VStack(spacing: 0) {
            filterPicker
            content
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Zadania")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddTask = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskView {
                Task { await model.load(showLoading: false) }
            }
        }
        .task { await model.loadIfNeeded() }
        .onAppear {
            Task { await model.refreshQuietly() }
        }
        .onChange(of: model.filter) { _, _ in
            Task { await model.load() }
        }
    }

    private var filterPicker: some View {
        Picker("Filtr", selection: $model.filter) {
            ForEach(ParentTasksViewModel.TaskFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, BJSpacing.l)
        .padding(.vertical, BJSpacing.s)
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
        } else {
            taskList
        }
    }

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: BJSpacing.m) {
                if model.pendingApprovalsCount > 0 {
                    approvalsEntryRow
                }
                if model.tasks.isEmpty {
                    EmptyStateView(
                        icon: "checklist",
                        title: model.filter.emptyTitle,
                        message: model.filter.emptyMessage
                    )
                } else {
                    ForEach(model.tasks) { task in
                        NavigationLink {
                            TaskDetailsView(taskId: task.id)
                        } label: {
                            ParentTaskRowView(task: task, showStatus: model.filter == .all)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(BJSpacing.l)
        }
        .refreshable { await model.load(showLoading: false) }
    }

    private var approvalsEntryRow: some View {
        NavigationLink {
            ApprovalsView()
        } label: {
            HStack(spacing: BJSpacing.m) {
                Image(systemName: "tray.full.fill")
                    .foregroundStyle(Color.bjAmber)
                Text("Czekają na akceptację (\(model.pendingApprovalsCount))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(BJSpacing.l)
            .background(Color.bjAmber.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: BJRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct ParentTaskRowView: View {
    let task: TaskDTO
    let showStatus: Bool

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: BJSpacing.s) {
                HStack(alignment: .top, spacing: BJSpacing.m) {
                    Text(task.name)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    PointsBadge(points: task.points)
                }
                HStack(spacing: BJSpacing.s) {
                    StatusChip(text: task.availability.displayName, color: ParentTaskChipStyle.color(for: task.availability))
                    StatusChip(text: task.recurrence.displayName, color: .gray)
                    if showStatus {
                        StatusChip(text: task.status.displayName, color: ParentTaskChipStyle.color(for: task.status))
                    }
                }
                if task.availability == .assigned, let childName = task.assignedChildName {
                    Label(childName, systemImage: "person.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

enum ParentTaskChipStyle {
    static func color(for status: AssignmentStatus) -> Color {
        switch status {
        case .inProgress: .blue
        case .pendingApproval: .bjAmber
        case .approved: .bjPrimary
        case .rejected: .bjDanger
        case .abandoned: .gray
        }
    }

    static func color(for status: TaskStatus) -> Color {
        switch status {
        case .active: .bjPrimary
        case .completed: .blue
        case .cancelled: .gray
        }
    }

    static func color(for availability: TaskAvailability) -> Color {
        switch availability {
        case .shared: .bjPrimaryDark
        case .assigned: .indigo
        }
    }
}
