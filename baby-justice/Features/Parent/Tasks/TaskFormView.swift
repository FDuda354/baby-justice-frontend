import SwiftUI
import Observation

@Observable
final class TaskFormViewModel {
    var name: String
    var descriptionText: String
    var availability: TaskAvailability
    var selectedChildId: Int64?
    var recurrence: TaskRecurrence
    private(set) var points: Int
    private(set) var pointsText: String

    private(set) var children: [ChildDTO] = []
    private(set) var isLoadingChildren = false
    private(set) var childrenLoadFailed = false
    private(set) var isSaving = false
    private(set) var errorMessage: String?

    private let submit: (CreateTaskRequest) async throws -> Void

    init(task: TaskDTO?, submit: @escaping (CreateTaskRequest) async throws -> Void) {
        self.submit = submit
        name = task?.name ?? ""
        descriptionText = task?.description ?? ""
        points = task?.points ?? 50
        pointsText = String(task?.points ?? 50)
        availability = task?.availability ?? .shared
        selectedChildId = task?.assignedChildId
        recurrence = task?.recurrence ?? .oneTime
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && points >= 1
            && (availability == .shared || selectedChildId != nil)
    }

    func updatePoints(fromText text: String) {
        let digits = String(text.filter(\.isNumber).prefix(4))
        pointsText = digits
        points = Int(digits) ?? 0
    }

    func updatePoints(fromStepper value: Int) {
        points = value
        pointsText = String(value)
    }

    func loadChildren() async {
        isLoadingChildren = true
        childrenLoadFailed = false
        do {
            children = try await APIClient.shared.children()
            preselectChildIfNeeded()
        } catch {
            childrenLoadFailed = true
        }
        isLoadingChildren = false
    }

    func preselectChildIfNeeded() {
        guard availability == .assigned, selectedChildId == nil else { return }
        selectedChildId = children.first?.id
    }

    func save() async -> Bool {
        guard isValid else { return false }
        isSaving = true
        errorMessage = nil
        let request = CreateTaskRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
            points: points,
            availability: availability,
            assignedChildId: availability == .assigned ? selectedChildId : nil,
            recurrence: recurrence
        )
        do {
            try await submit(request)
            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
            return false
        }
    }
}

struct TaskFormView: View {
    @Bindable var model: TaskFormViewModel
    let submitTitle: String
    let onSuccess: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BJSpacing.l) {
                FormTextField(label: "Nazwa zadania", text: $model.name)
                descriptionEditor
                pointsSection
                availabilitySection
                recurrenceSection
                if let message = model.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(Color.bjDanger)
                }
                PrimaryButton(title: submitTitle, isLoading: model.isSaving) {
                    Task {
                        if await model.save() {
                            onSuccess()
                        }
                    }
                }
                .disabled(!model.isValid)
                .opacity(model.isValid ? 1 : 0.5)
            }
            .padding(BJSpacing.l)
        }
        .background(Color(.systemGroupedBackground))
        .task { await model.loadChildren() }
        .onChange(of: model.availability) { _, _ in
            model.preselectChildIfNeeded()
        }
    }

    private var descriptionEditor: some View {
        VStack(alignment: .leading, spacing: BJSpacing.xs) {
            Text("Opis")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            TextEditor(text: $model.descriptionText)
                .frame(minHeight: 100)
                .padding(BJSpacing.s)
                .scrollContentBackground(.hidden)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: BJRadius.field, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: BJRadius.field, style: .continuous)
                        .strokeBorder(Color.bjPrimary.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private var pointsSection: some View {
        VStack(alignment: .leading, spacing: BJSpacing.xs) {
            Text("Punkty")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            HStack(spacing: BJSpacing.m) {
                TextField("", text: pointsTextBinding)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 80, height: BJSize.fieldHeight)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: BJRadius.field, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: BJRadius.field, style: .continuous)
                            .strokeBorder(Color.bjPrimary.opacity(0.2), lineWidth: 1)
                    )
                Stepper("Punkty", value: stepperBinding, in: 5...500, step: 5)
                    .labelsHidden()
                Spacer()
                PointsBadge(points: model.points)
            }
        }
    }

    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: BJSpacing.s) {
            Text("Dostępność")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            Picker("Dostępność", selection: $model.availability) {
                ForEach(TaskAvailability.allCases, id: \.self) { availability in
                    Text(availability.displayName).tag(availability)
                }
            }
            .pickerStyle(.segmented)
            if model.availability == .assigned {
                childPicker
            }
        }
    }

    @ViewBuilder
    private var childPicker: some View {
        if model.isLoadingChildren {
            HStack(spacing: BJSpacing.s) {
                ProgressView()
                Text("Wczytywanie dzieci…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } else if model.childrenLoadFailed {
            VStack(alignment: .leading, spacing: BJSpacing.xs) {
                Text("Nie udało się wczytać listy dzieci.")
                    .font(.footnote)
                    .foregroundStyle(Color.bjDanger)
                Button("Spróbuj ponownie") {
                    Task { await model.loadChildren() }
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.bjAccent)
            }
        } else if model.children.isEmpty {
            Text("Najpierw dodaj dziecko w zakładce Dzieci.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            HStack {
                Text("Dziecko")
                    .font(.subheadline)
                Spacer()
                Picker("Dziecko", selection: $model.selectedChildId) {
                    ForEach(model.children) { child in
                        Text(child.name).tag(child.id as Int64?)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.bjAccent)
            }
            .padding(.horizontal, BJSpacing.m)
            .frame(height: BJSize.fieldHeight)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: BJRadius.field, style: .continuous))
        }
    }

    private var recurrenceSection: some View {
        VStack(alignment: .leading, spacing: BJSpacing.s) {
            Text("Powtarzalność")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            Picker("Powtarzalność", selection: $model.recurrence) {
                ForEach(TaskRecurrence.allCases, id: \.self) { recurrence in
                    Text(recurrence.displayName).tag(recurrence)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var pointsTextBinding: Binding<String> {
        Binding(
            get: { model.pointsText },
            set: { model.updatePoints(fromText: $0) }
        )
    }

    private var stepperBinding: Binding<Int> {
        Binding(
            get: { model.points },
            set: { model.updatePoints(fromStepper: $0) }
        )
    }
}
