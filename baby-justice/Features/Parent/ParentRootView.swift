import SwiftUI

struct ParentRootView: View {
    @State private var selectedTab = 0
    private let badges = ParentBadgesStore.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ParentDashboardView()
            }
            .tabItem {
                Label("Panel", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                ParentTasksView()
            }
            .tabItem {
                Label("Zadania", systemImage: "checklist")
            }
            .badge(badges.pendingApprovalsCount)
            .tag(1)

            NavigationStack {
                ChildrenListView()
            }
            .tabItem {
                Label("Dzieci", systemImage: "person.2.fill")
            }
            .tag(2)

            NavigationStack {
                ParentRewardsHomeView()
            }
            .tabItem {
                Label("Nagrody", systemImage: "gift.fill")
            }
            .badge(badges.pendingDeliveriesCount)
            .tag(3)

            NavigationStack {
                ParentMoreView()
            }
            .tabItem {
                Label("Więcej", systemImage: "ellipsis.circle.fill")
            }
            .badge(badges.unreadNotificationsCount)
            .tag(4)
        }
        .task { await badges.refresh() }
        .onChange(of: selectedTab) { _, _ in
            badges.refreshSoon()
        }
    }
}
