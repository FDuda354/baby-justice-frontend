import SwiftUI

struct ChildDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ChildDetailsViewModel
    @State private var showingAdjustPoints = false
    @State private var showingDetachConfirmation = false

    init(childId: Int64) {
        _viewModel = State(initialValue: ChildDetailsViewModel(childId: childId))
    }

    var body: some View {
        ScrollView {
            content
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.child?.name ?? "Dziecko")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
        .sheet(isPresented: $showingAdjustPoints) {
            if let child = viewModel.child {
                AdjustPointsView(child: child) { updated in
                    viewModel.child = updated
                }
            }
        }
        .confirmationDialog("Usunąć z rodziny?", isPresented: $showingDetachConfirmation, titleVisibility: .visible) {
            Button("Usuń z rodziny", role: .destructive) {
                Task {
                    if await viewModel.detachChild() {
                        dismiss()
                    }
                }
            }
            Button("Anuluj", role: .cancel) {}
        } message: {
            Text("Dziecko opuści rodzinę, ale jego konto, punkty i historia zostaną zachowane. Możesz dodać je ponownie jego kodem dziecka.")
        }
        .overlay {
            if viewModel.isDetaching {
                LoadingOverlay()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.child == nil {
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.top, 120)
        } else if let child = viewModel.child {
            VStack(spacing: BJSpacing.l) {
                if let message = viewModel.errorMessage {
                    ErrorBanner(message: message) {
                        Task { await viewModel.load() }
                    }
                }
                VStack(spacing: BJSpacing.l) {
                    profileHeader(child)
                    actionFeedback
                    actionsCard
                }
                .padding(.horizontal, BJSpacing.l)
            }
            .padding(.vertical, BJSpacing.l)
        } else if let message = viewModel.errorMessage {
            ErrorBanner(message: message) {
                Task { await viewModel.load() }
            }
            .padding(.top, BJSpacing.xxl)
        }
    }

    private func profileHeader(_ child: ChildDTO) -> some View {
        CardView {
            VStack(spacing: BJSpacing.m) {
                AvatarView(hasAvatar: child.hasAvatar, childId: child.id, size: 96)
                Text(child.name)
                    .font(.title2.bold())
                    .foregroundStyle(Color.bjInk)
                if let age = ChildBirthDate.ageText(forIso: child.birthDate) {
                    Text("\(age) • ur. \(Formatters.formattedDay(child.birthDate))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("E-mail: \(child.email)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                PointsBadge(points: child.pointsBalance)
                    .font(.title3)
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var actionFeedback: some View {
        if let error = viewModel.actionError {
            Text(error)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.bjDanger)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var actionsCard: some View {
        CardView {
            VStack(spacing: 0) {
                actionRow(icon: "plusminus.circle.fill", color: .bjPrimary, title: "Dodaj / odejmij punkty") {
                    showingAdjustPoints = true
                }
                Divider()
                actionRow(icon: "person.crop.circle.badge.minus", color: .bjDanger, title: "Usuń z rodziny") {
                    showingDetachConfirmation = true
                }
            }
        }
    }

    private func actionRow(icon: String, color: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: BJSpacing.m) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 28)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(color == Color.bjDanger ? Color.bjDanger : Color.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, BJSpacing.m)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
