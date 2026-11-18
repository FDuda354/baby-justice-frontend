import SwiftUI

struct ParentHistoryView: View {
    @State private var viewModel = ParentHistoryViewModel()

    var body: some View {
        content
            .bjPinnedHeader { segmentPicker }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Historia")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                childFilterMenu
            }
        }
        .task {
            await viewModel.loadInitial()
        }
        .onChange(of: viewModel.segment) { _, _ in
            Task { await viewModel.loadCurrentSegment() }
        }
        .onChange(of: viewModel.selectedChildId) { _, _ in
            Task { await viewModel.loadCurrentSegment() }
        }
    }

    private var segmentPicker: some View {
        Picker("Rodzaj historii", selection: $viewModel.segment) {
            ForEach(ParentHistorySegment.allCases) { segment in
                Text(segment.title).tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, BJSpacing.l)
        .padding(.vertical, BJSpacing.s)
        .bjReadableWidth()
    }

    private var childFilterMenu: some View {
        Menu {
            Picker("Dziecko", selection: $viewModel.selectedChildId) {
                Text("Wszystkie dzieci").tag(Int64?.none)
                ForEach(viewModel.children) { child in
                    Text(child.name).tag(Int64?.some(child.id))
                }
            }
        } label: {
            Label(viewModel.selectedChildName, systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage = viewModel.errorMessage {
            BJScrollView {
                ErrorBanner(message: errorMessage) {
                    Task { await viewModel.loadCurrentSegment() }
                }
                .padding(.top, BJSpacing.xl)
            }
        } else if viewModel.isLoading && currentSegmentIsEmpty {
            ProgressView("Wczytywanie…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            segmentList
        }
    }

    private var currentSegmentIsEmpty: Bool {
        switch viewModel.segment {
        case .points: viewModel.pointsHistory.isEmpty
        case .purchases: viewModel.purchasesHistory.isEmpty
        case .tasks: viewModel.tasksHistory.isEmpty
        }
    }

    @ViewBuilder
    private var segmentList: some View {
        switch viewModel.segment {
        case .points:
            if viewModel.pointsHistory.isEmpty {
                emptyState
            } else {
                historyCards(viewModel.pointsHistory) { entry in
                    PointsHistoryRow(entry: entry)
                }
            }
        case .purchases:
            if viewModel.purchasesHistory.isEmpty {
                emptyState
            } else {
                historyCards(viewModel.purchasesHistory) { purchase in
                    PurchaseHistoryRow(purchase: purchase)
                }
            }
        case .tasks:
            if viewModel.tasksHistory.isEmpty {
                emptyState
            } else {
                historyCards(viewModel.tasksHistory) { assignment in
                    TaskHistoryRow(assignment: assignment)
                }
            }
        }
    }

    private func historyCards<Item: Identifiable, Row: View>(
        _ items: [Item],
        @ViewBuilder row: @escaping (Item) -> Row
    ) -> some View {
        BJScrollView {
            LazyVStack(spacing: BJSpacing.m) {
                ForEach(items) { item in
                    CardView {
                        row(item)
                    }
                }
            }
            .padding(.horizontal, BJSpacing.l)
            .padding(.vertical, BJSpacing.s)
            .padding(.bottom, BJSpacing.xl)
        }
        .refreshable { await viewModel.loadCurrentSegment() }
    }

    @ViewBuilder
    private var emptyState: some View {
        BJScrollView {
            switch viewModel.segment {
            case .points:
                EmptyStateView(
                    icon: "star.circle",
                    title: "Brak historii punktów",
                    message: "Gdy dzieci zaczną zdobywać i wydawać punkty, zobaczysz tu wszystkie zmiany."
                )
            case .purchases:
                EmptyStateView(
                    icon: "cart",
                    title: "Brak zakupów",
                    message: "Tutaj pojawią się nagrody kupione przez dzieci w swoich sklepikach."
                )
            case .tasks:
                EmptyStateView(
                    icon: "checklist",
                    title: "Brak rozliczonych zadań",
                    message: "Znajdziesz tu zadania, które zostały zaliczone, odrzucone lub porzucone."
                )
            }
        }
        .refreshable { await viewModel.loadCurrentSegment() }
    }
}

private struct PointsHistoryRow: View {
    let entry: PointsTransactionDTO

    var body: some View {
        HStack(alignment: .top, spacing: BJSpacing.m) {
            VStack(alignment: .leading, spacing: BJSpacing.xs) {
                Text(entry.childName)
                    .font(.subheadline.weight(.semibold))
                Text(entry.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(Formatters.formatted(date: entry.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: BJSpacing.xs) {
                Text(Formatters.signedPoints(entry.delta))
                    .font(.headline)
                    .foregroundStyle(entry.delta >= 0 ? Color.bjPrimary : Color.bjDanger)
                Text("Saldo: \(entry.balanceAfter)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, BJSpacing.xs)
    }
}

private struct PurchaseHistoryRow: View {
    let purchase: RewardPurchaseDTO

    var body: some View {
        VStack(alignment: .leading, spacing: BJSpacing.xs) {
            HStack {
                Text(purchase.rewardName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                PointsBadge(points: purchase.costPoints)
            }
            HStack {
                Text(purchase.childName)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                StatusChip(text: purchase.status.displayName, color: purchase.status.chipColor)
            }
            Text(Formatters.formatted(date: purchase.purchasedAt))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, BJSpacing.xs)
    }
}

private struct TaskHistoryRow: View {
    let assignment: TaskAssignmentDTO

    var body: some View {
        VStack(alignment: .leading, spacing: BJSpacing.xs) {
            HStack {
                Text(assignment.taskName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                PointsBadge(points: assignment.points)
            }
            HStack {
                Text(assignment.childName)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                StatusChip(text: assignment.status.displayName, color: assignment.status.chipColor)
            }
            if let resolvedAt = assignment.resolvedAt {
                Text(Formatters.formatted(date: resolvedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let reason = assignment.rejectionReason, !reason.isEmpty {
                Text("Powód odrzucenia: \(reason)")
                    .font(.footnote)
                    .foregroundStyle(Color.bjDanger)
            }
        }
        .padding(.vertical, BJSpacing.xs)
    }
}
