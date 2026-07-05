import SwiftUI

struct ChildRootView: View {
    @State private var selectedTab = 0
    private let badges = ChildBadgesStore.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ChildDashboardView()
            }
            .tabItem {
                Label("Start", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                ChildTasksHomeView()
            }
            .tabItem {
                Label("Zadania", systemImage: "checklist")
            }
            .tag(1)

            NavigationStack {
                ShopView()
            }
            .tabItem {
                Label("Sklep", systemImage: "bag.fill")
            }
            .badge(badges.deliveredPurchasesCount)
            .tag(2)

            NavigationStack {
                ChildHistoryHomeView()
            }
            .tabItem {
                Label("Historia", systemImage: "clock.fill")
            }
            .tag(3)

            NavigationStack {
                ChildProfileView()
            }
            .tabItem {
                Label("Profil", systemImage: "person.crop.circle.fill")
            }
            .tag(4)
        }
        .task { await badges.refresh() }
        .onChange(of: selectedTab) { _, _ in
            badges.refreshSoon()
        }
    }
}
