import SwiftUI

struct ChildrenListView: View {
    @State private var viewModel = ChildrenListViewModel()
    @State private var showingAdd = false

    var body: some View {
        ScrollView {
            content
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dzieci")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Dodaj dziecko")
            }
        }
        .refreshable { await viewModel.load() }
        .onAppear {
            Task { await viewModel.load() }
        }
        .sheet(isPresented: $showingAdd) {
            AddChildByCodeView {
                Task { await viewModel.load() }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && !viewModel.hasLoaded {
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.top, 120)
        } else if viewModel.hasLoaded {
            VStack(spacing: BJSpacing.l) {
                if let message = viewModel.errorMessage {
                    ErrorBanner(message: message) {
                        Task { await viewModel.load() }
                    }
                }
                if viewModel.children.isEmpty {
                    emptyState
                } else {
                    childrenCards
                }
            }
            .padding(.vertical, BJSpacing.l)
        } else if let message = viewModel.errorMessage {
            ErrorBanner(message: message) {
                Task { await viewModel.load() }
            }
            .padding(.top, BJSpacing.xxl)
        }
    }

    private var emptyState: some View {
        VStack(spacing: BJSpacing.l) {
            EmptyStateView(
                icon: "person.badge.plus",
                title: "Brak dzieci",
                message: "Dziecko zakłada własne konto w aplikacji i dostaje kod dziecka. Dodaj je do rodziny tym kodem."
            )
            PrimaryButton(title: "Dodaj dziecko") {
                showingAdd = true
            }
            .padding(.horizontal, BJSpacing.xl)
        }
    }

    private var childrenCards: some View {
        VStack(spacing: BJSpacing.m) {
            ForEach(viewModel.children) { child in
                NavigationLink {
                    ChildDetailsView(childId: child.id)
                } label: {
                    childCard(child)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, BJSpacing.l)
    }

    private func childCard(_ child: ChildDTO) -> some View {
        CardView {
            HStack(spacing: BJSpacing.m) {
                AvatarView(hasAvatar: child.hasAvatar, childId: child.id, size: 52)
                VStack(alignment: .leading, spacing: BJSpacing.xs) {
                    Text(child.name)
                        .font(.headline)
                    Text(subtitle(for: child))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: BJSpacing.s)
                PointsBadge(points: child.pointsBalance)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func subtitle(for child: ChildDTO) -> String {
        if let age = ChildBirthDate.ageText(forIso: child.birthDate) {
            return "\(age) • \(child.email)"
        }
        return child.email
    }
}
