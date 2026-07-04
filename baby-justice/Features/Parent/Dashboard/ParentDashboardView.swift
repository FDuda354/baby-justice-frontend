import SwiftUI

struct ParentDashboardView: View {
    @State private var viewModel = ParentDashboardViewModel()

    var body: some View {
        ScrollView {
            content
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Panel")
        .refreshable { await viewModel.load() }
        .onAppear {
            Task { await viewModel.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.dashboard == nil {
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.top, 120)
        } else if let dashboard = viewModel.dashboard {
            VStack(spacing: BJSpacing.l) {
                if let message = viewModel.errorMessage {
                    ErrorBanner(message: message) {
                        Task { await viewModel.load() }
                    }
                }
                VStack(spacing: BJSpacing.l) {
                    familyHeader(dashboard)
                    statsRow(dashboard)
                    childrenSection(dashboard)
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

    private func familyHeader(_ dashboard: ParentDashboardDTO) -> some View {
        CardView {
            HStack(spacing: BJSpacing.m) {
                Image(systemName: "house.and.flag.fill")
                    .font(.title2)
                    .foregroundStyle(Color.bjPrimary)
                Text(dashboard.familyName)
                    .font(.title2.bold())
                    .foregroundStyle(Color.bjInk)
                Spacer()
            }
        }
    }

    private func statsRow(_ dashboard: ParentDashboardDTO) -> some View {
        HStack(spacing: BJSpacing.m) {
            NavigationLink {
                ApprovalsView()
            } label: {
                StatCard(title: "Do akceptacji", count: dashboard.pendingApprovalsCount, icon: "checkmark.seal.fill")
            }
            NavigationLink {
                DeliveriesView()
            } label: {
                StatCard(title: "Do wydania", count: dashboard.pendingDeliveriesCount, icon: "shippingbox.fill")
            }
            NavigationLink {
                ParentNotificationsView()
            } label: {
                StatCard(title: "Powiadomienia", count: dashboard.unreadNotificationsCount, icon: "bell.fill")
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func childrenSection(_ dashboard: ParentDashboardDTO) -> some View {
        SectionHeader(title: "Dzieci")
        if dashboard.children.isEmpty {
            EmptyStateView(
                icon: "person.badge.plus",
                title: "Brak dzieci",
                message: "Dodaj dziecko jego kodem w zakładce Dzieci, aby zacząć przydzielać zadania i nagrody."
            )
        } else {
            ForEach(dashboard.children) { child in
                NavigationLink {
                    ChildDetailsView(childId: child.id)
                } label: {
                    childCard(child)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func childCard(_ child: ChildSummaryDTO) -> some View {
        CardView {
            HStack(spacing: BJSpacing.m) {
                AvatarView(hasAvatar: child.hasAvatar, childId: child.id, size: 48)
                VStack(alignment: .leading, spacing: BJSpacing.xs) {
                    Text(child.name)
                        .font(.headline)
                    Text("\(child.activeTasksCount) w trakcie • \(child.pendingApprovalsCount) do akceptacji • \(child.pendingDeliveriesCount) do wydania")
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
}

private struct StatCard: View {
    let title: String
    let count: Int
    let icon: String

    private var highlighted: Bool { count > 0 }

    var body: some View {
        VStack(spacing: BJSpacing.s) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(highlighted ? Color.bjAmber : Color.bjPrimary)
            Text("\(count)")
                .font(.title2.bold())
                .foregroundStyle(highlighted ? Color.bjAmber : Color.primary)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BJSpacing.l)
        .padding(.horizontal, BJSpacing.xs)
        .background(highlighted ? Color.bjAmber.opacity(0.12) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: BJRadius.card, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
