import SwiftUI

struct ChildDashboardView: View {
    @State private var viewModel = ChildDashboardViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Ładowanie...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let dashboard = viewModel.dashboard {
                dashboardContent(dashboard)
            } else {
                VStack {
                    Spacer()
                    ErrorBanner(message: viewModel.errorMessage ?? "Coś poszło nie tak.") {
                        Task { await viewModel.initialLoad() }
                    }
                    Spacer()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Start")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ChildNotificationsView()
                } label: {
                    bellIcon(unreadCount: viewModel.dashboard?.unreadNotificationsCount ?? 0)
                }
            }
        }
        .task { await viewModel.loadIfNeeded() }
        .onAppear {
            if viewModel.dashboard != nil {
                Task { await viewModel.refresh() }
            }
        }
    }

    private func dashboardContent(_ dashboard: ChildDashboardDTO) -> some View {
        ScrollView {
            VStack(spacing: BJSpacing.l) {
                if let message = viewModel.errorMessage {
                    ErrorBanner(message: message) {
                        Task { await viewModel.refresh() }
                    }
                }
                VStack(spacing: BJSpacing.l) {
                    HeroCard(dashboard: dashboard)
                    if dashboard.hasFamily {
                        statsGrid(dashboard)
                        recentPointsSection(dashboard)
                    } else {
                        NoFamilyCard(childCode: dashboard.childCode)
                    }
                }
                .padding(.horizontal, BJSpacing.l)
            }
            .padding(.vertical, BJSpacing.l)
        }
        .refreshable { await viewModel.refresh() }
    }

    private func statsGrid(_ dashboard: ChildDashboardDTO) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: BJSpacing.m), GridItem(.flexible(), spacing: BJSpacing.m)], spacing: BJSpacing.m) {
            StatTile(icon: "sparkles", value: dashboard.availableTasksCount, label: "Dostępne zadania", color: .bjPrimary)
            StatTile(icon: "figure.run", value: dashboard.activeTasksCount, label: "W trakcie", color: .blue)
            StatTile(icon: "hourglass", value: dashboard.pendingApprovalsCount, label: "Czekają na akceptację", color: .bjAmber)
            StatTile(icon: "gift.fill", value: dashboard.deliveredPurchasesCount, label: "Nagrody do odebrania", color: .purple)
        }
    }

    @ViewBuilder
    private func recentPointsSection(_ dashboard: ChildDashboardDTO) -> some View {
        SectionHeader(title: "Ostatnie punkty")
        if dashboard.recentTransactions.isEmpty {
            EmptyStateView(
                icon: "star.circle.fill",
                title: "Zbieraj punkty!",
                message: "Zrób pierwsze zadanie, a Twoje punkty pojawią się tutaj. Dasz radę!"
            )
        } else {
            CardView {
                VStack(spacing: BJSpacing.m) {
                    ForEach(dashboard.recentTransactions) { transaction in
                        TransactionRow(transaction: transaction)
                        if transaction.id != dashboard.recentTransactions.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func bellIcon(unreadCount: Int) -> some View {
        Image(systemName: "bell.fill")
            .foregroundStyle(Color.bjAccent)
            .overlay(alignment: .topTrailing) {
                if unreadCount > 0 {
                    Text("\(min(unreadCount, 99))")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Color.bjDanger)
                        .clipShape(Circle())
                        .offset(x: 10, y: -10)
                }
            }
    }
}

private struct NoFamilyCard: View {
    let childCode: String

    @State private var codeCopied = false

    var body: some View {
        VStack(spacing: BJSpacing.m) {
            Image(systemName: "house.and.flag.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.bjPrimary)
            Text("Jeszcze chwila!")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.bjInk)
            Text("Nie należysz jeszcze do żadnej rodziny. Poproś rodzica, aby dodał Cię do rodziny Twoim kodem dziecka:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(childCode)
                .font(.system(size: 36, weight: .heavy, design: .monospaced))
                .kerning(5)
                .foregroundStyle(Color.bjInk)
            Button {
                copyCode()
            } label: {
                Label(codeCopied ? "Skopiowano" : "Kopiuj kod", systemImage: codeCopied ? "checkmark" : "doc.on.doc")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.bjAccent)
            }
            Text("Gdy dołączysz do rodziny, pojawią się tu zadania i nagrody.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(BJSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color.bjMint)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func copyCode() {
        UIPasteboard.general.string = childCode
        codeCopied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            codeCopied = false
        }
    }
}

private struct HeroCard: View {
    let dashboard: ChildDashboardDTO

    var body: some View {
        VStack(alignment: .leading, spacing: BJSpacing.l) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: BJSpacing.xs) {
                    Text("Cześć, \(dashboard.name)!")
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundStyle(.white)
                    Text("Twoje punkty rosną!")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                AvatarView(hasAvatar: dashboard.hasAvatar, childId: SessionStore.shared.accountId ?? 0, size: 56)
            }
            HStack(alignment: .firstTextBaseline, spacing: BJSpacing.s) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.bjAmber)
                Text("\(dashboard.pointsBalance)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("pkt")
                    .font(.title3.bold())
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(BJSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [.bjPrimary, .bjPrimaryDark], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.bjPrimaryDark.opacity(0.25), radius: 10, x: 0, y: 4)
    }
}

private struct StatTile: View {
    let icon: String
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: BJSpacing.s) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                Spacer()
                Text("\(value)")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(value > 0 ? Color.primary : Color.secondary)
            }
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2, reservesSpace: true)
        }
        .padding(BJSpacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

private struct TransactionRow: View {
    let transaction: PointsTransactionDTO

    var body: some View {
        HStack(spacing: BJSpacing.m) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(iconColor)
                .frame(width: 34, height: 34)
                .background(iconColor.opacity(0.15))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text(Formatters.formatted(date: transaction.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: BJSpacing.s)
            Text(Formatters.signedPoints(transaction.delta))
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(deltaColor)
        }
    }

    private var deltaColor: Color {
        if transaction.delta > 0 { return .bjPrimary }
        if transaction.delta < 0 { return .bjDanger }
        return .secondary
    }

    private var icon: String {
        switch transaction.type {
        case .taskReward: "checkmark.seal.fill"
        case .manualAdjustment: "slider.horizontal.3"
        case .purchase: "gift.fill"
        }
    }

    private var iconColor: Color {
        switch transaction.type {
        case .taskReward: .bjPrimary
        case .manualAdjustment: .blue
        case .purchase: .bjAmber
        }
    }
}
