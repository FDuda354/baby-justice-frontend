import SwiftUI

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: TaskFormViewModel
    private let onSaved: () -> Void

    init(task: TaskDTO, onSaved: @escaping () -> Void) {
        self.onSaved = onSaved
        _model = State(initialValue: TaskFormViewModel(task: task) { request in
            _ = try await APIClient.shared.updateTask(taskId: task.id, request)
        })
    }

    var body: some View {
        NavigationStack {
            TaskFormView(model: model, submitTitle: "Zapisz zmiany") {
                onSaved()
                dismiss()
            }
            .navigationTitle("Edytuj zadanie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
            }
        }
    }
}
