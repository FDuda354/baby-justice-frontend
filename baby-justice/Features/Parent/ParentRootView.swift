import SwiftUI

struct ParentRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ParentDashboardView()
            }
            .tabItem {
                Label("Panel", systemImage: "house.fill")
            }

            NavigationStack {
                ParentTasksView()
            }
            .tabItem {
                Label("Zadania", systemImage: "checklist")
            }

            NavigationStack {
                ChildrenListView()
            }
            .tabItem {
                Label("Dzieci", systemImage: "person.2.fill")
            }

            NavigationStack {
                ParentRewardsHomeView()
            }
            .tabItem {
                Label("Nagrody", systemImage: "gift.fill")
            }

            NavigationStack {
                ParentMoreView()
            }
            .tabItem {
                Label("Więcej", systemImage: "ellipsis.circle.fill")
            }
        }
    }
}
