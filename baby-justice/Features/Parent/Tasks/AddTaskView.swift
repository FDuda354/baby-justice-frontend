import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: TaskFormViewModel
    private let onSaved: () -> Void

    init(onSaved: @escaping () -> Void) {
        self.onSaved = onSaved
        _model = State(initialValue: TaskFormViewModel(task: nil) { request in
            _ = try await APIClient.shared.createTask(request)
        })
    }

    var body: some View {
        NavigationStack {
            TaskFormView(model: model, submitTitle: "Dodaj zadanie") {
                onSaved()
                dismiss()
            }
            .navigationTitle("Nowe zadanie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
            }
        }
    }
}
