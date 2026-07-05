import SwiftUI

struct TaskDetailsView: View {
    @State private var model: TaskDetailsViewModel

    init(taskId: Int64) {
        _model = State(initialValue: TaskDetailsViewModel(taskId: taskId))
    }

    var body: some View {
        ZStack {
            content
            if model.isCancelling {
                LoadingOverlay()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Szczegóły zadania")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.loadIfNeeded() }
        .sheet(isPresented: $model.showEditSheet) {
            if let task = model.details?.task {
                EditTaskView(task: task) {
                    Task { await model.load(showLoading: false) }
                }
            }
        }
        .alert("Czy na pewno anulować to zadanie?", isPresented: $model.showCancelConfirmation) {
            Button("Anuluj zadanie", role: .destructive) {
                Task { await model.cancelTask() }
            }
            Button("Wróć", role: .cancel) {}
        } message: {
            Text("Wszystkie rozpoczęte podejścia dzieci zostaną porzucone.")
        }
        .alert(
            "Nie udało się anulować zadania",
            isPresented: cancelErrorBinding
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.cancelErrorMessage ?? "")
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
        } else if let details = model.details {
            detailsContent(details)
        }
    }

    private func detailsContent(_ details: TaskDetailsDTO) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BJSpacing.l) {
                taskCard(details.task)
                if details.task.status == .active {
                    actionButtons
                }
                SectionHeader(title: "Historia podejść")
                if details.assignments.isEmpty {
                    EmptyStateView(
                        icon: "person.badge.clock",
                        title: "Brak podejść",
                        message: "Nikt jeszcze nie podjął tego zadania."
                    )
                } else {
                    ForEach(details.assignments) { assignment in
                        ParentAssignmentHistoryRow(assignment: assignment)
                    }
                }
            }
            .padding(BJSpacing.l)
        }
        .refreshable { await model.load(showLoading: false) }
    }

    private func taskCard(_ task: TaskDTO) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: BJSpacing.m) {
                HStack(alignment: .top, spacing: BJSpacing.m) {
                    Text(task.name)
                        .font(.title3.bold())
                    Spacer()
                    PointsBadge(points: task.points)
                        .font(.title3)
                }
                HStack(spacing: BJSpacing.s) {
                    StatusChip(text: task.status.displayName, color: ParentTaskChipStyle.color(for: task.status))
                    StatusChip(text: task.availability.displayName, color: ParentTaskChipStyle.color(for: task.availability))
                    StatusChip(text: task.recurrence.displayName, color: .gray)
                }
                if task.availability == .assigned, let childName = task.assignedChildName {
                    Label(childName, systemImage: "person.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Label("Utworzono: \(Formatters.formatted(date: task.createdAt))", systemImage: "calendar")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: BJSpacing.m) {
            SecondaryButton(title: "Edytuj") {
                model.showEditSheet = true
            }
            Button {
                model.showCancelConfirmation = true
            } label: {
                Text("Anuluj zadanie")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: BJSize.buttonHeight)
                    .background(Color.bjDanger.opacity(0.12))
                    .foregroundStyle(Color.bjDanger)
                    .clipShape(RoundedRectangle(cornerRadius: BJRadius.button, style: .continuous))
            }
        }
    }

    private var cancelErrorBinding: Binding<Bool> {
        Binding(
            get: { model.cancelErrorMessage != nil },
            set: { if !$0 { model.cancelErrorMessage = nil } }
        )
    }
}

struct ParentAssignmentHistoryRow: View {
    let assignment: TaskAssignmentDTO

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: BJSpacing.s) {
                HStack(spacing: BJSpacing.m) {
                    Text(assignment.childName)
                        .font(.headline)
                    Spacer()
                    StatusChip(text: assignment.status.displayName, color: ParentTaskChipStyle.color(for: assignment.status))
                }
                dateRow(label: "Przyjęto", date: assignment.acceptedAt)
                if let completedAt = assignment.completedAt {
                    dateRow(label: "Ukończono", date: completedAt)
                }
                if let resolvedAt = assignment.resolvedAt {
                    dateRow(label: "Rozstrzygnięto", date: resolvedAt)
                }
                if let reason = assignment.rejectionReason, !reason.isEmpty {
                    Text("Powód odrzucenia: \(reason)")
                        .font(.footnote)
                        .foregroundStyle(Color.bjDanger)
                }
            }
        }
    }

    private func dateRow(label: String, date: Date) -> some View {
        HStack {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Text(Formatters.formatted(date: date))
                .font(.footnote)
        }
    }
}
