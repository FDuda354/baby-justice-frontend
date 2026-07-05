import SwiftUI

struct ChildAssignmentDetailView: View {
    let assignment: TaskAssignmentDTO
    let viewModel: ChildTasksViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var showCompleteConfirmation = false
    @State private var showAbandonDialog = false
    @State private var completedTrigger = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BJSpacing.l) {
                headerCard
            }
            .padding(BJSpacing.l)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Moje zadanie")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
        .sensoryFeedback(.success, trigger: completedTrigger)
        .alert("Wysłać do sprawdzenia?", isPresented: $showCompleteConfirmation) {
            Button("Tak, gotowe!") {
                Task { await complete() }
            }
            Button("Jeszcze nie", role: .cancel) {}
        } message: {
            Text("Rodzic sprawdzi zadanie i przyzna Ci punkty.")
        }
        .alert("Na pewno rezygnujesz?", isPresented: $showAbandonDialog) {
            Button("Rezygnuję z zadania", role: .destructive) {
                Task { await abandon() }
            }
            Button("Zostaję przy zadaniu", role: .cancel) {}
        } message: {
            Text("Zadanie wróci do puli i punkty przepadną.")
        }
        .alert("Ups!", isPresented: actionErrorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.actionErrorMessage ?? "")
        }
    }

    private var headerCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: BJSpacing.m) {
                Text(assignment.taskName)
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                HStack(alignment: .firstTextBaseline, spacing: BJSpacing.s) {
                    Image(systemName: "star.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.bjAmber)
                    Text("+\(assignment.points)")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.bjAccent)
                    Text("pkt czeka na Ciebie")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                StatusChip(text: assignment.status.displayName, color: .blue)
                Label("Wzięte: \(Formatters.formatted(date: assignment.acceptedAt))", systemImage: "calendar")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionBar: some View {
        VStack(spacing: BJSpacing.s) {
            PrimaryButton(title: "Zrobione ✅", isLoading: viewModel.isPerformingAction) {
                showCompleteConfirmation = true
            }
            Button {
                showAbandonDialog = true
            } label: {
                Text("Rezygnuję")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.bjDanger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BJSpacing.s)
            }
            .disabled(viewModel.isPerformingAction)
        }
        .padding(BJSpacing.l)
        .background(.regularMaterial)
    }

    private var actionErrorPresented: Binding<Bool> {
        Binding(
            get: { viewModel.actionErrorMessage != nil },
            set: { presented in
                if !presented {
                    viewModel.actionErrorMessage = nil
                }
            }
        )
    }

    private func complete() async {
        let succeeded = await viewModel.complete(assignment)
        if succeeded {
            completedTrigger.toggle()
            try? await Task.sleep(nanoseconds: 250_000_000)
            dismiss()
        }
    }

    private func abandon() async {
        let succeeded = await viewModel.abandon(assignment)
        if succeeded {
            dismiss()
        }
    }
}
