import SwiftUI

struct ChildTaskDetailView: View {
    let task: TaskDTO
    let viewModel: ChildTasksViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var acceptedTrigger = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BJSpacing.l) {
                headerCard
                if !task.description.isEmpty {
                    descriptionCard
                }
            }
            .padding(BJSpacing.l)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Zadanie")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Biorę to! (+\(task.points) pkt)", isLoading: viewModel.isPerformingAction) {
                Task { await accept() }
            }
            .padding(BJSpacing.l)
            .background(.regularMaterial)
        }
        .sensoryFeedback(.success, trigger: acceptedTrigger)
        .alert("Ups!", isPresented: actionErrorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.actionErrorMessage ?? "")
        }
    }

    private var headerCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: BJSpacing.m) {
                Text(task.name)
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                HStack(alignment: .firstTextBaseline, spacing: BJSpacing.s) {
                    Image(systemName: "star.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.bjAmber)
                    Text("+\(task.points)")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.bjAccent)
                    Text("pkt do zdobycia")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: BJSpacing.s) {
                    if task.availability == .shared {
                        StatusChip(text: "Wspólne", color: .indigo)
                    }
                    if task.recurrence == .repeatable {
                        StatusChip(text: "Powtarzalne", color: .teal)
                    }
                }
            }
        }
    }

    private var descriptionCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: BJSpacing.s) {
                Text("Co trzeba zrobić?")
                    .font(.headline)
                Text(task.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
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

    private func accept() async {
        let succeeded = await viewModel.accept(task)
        if succeeded {
            acceptedTrigger.toggle()
            try? await Task.sleep(nanoseconds: 250_000_000)
            dismiss()
        }
    }
}
