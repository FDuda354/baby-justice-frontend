import SwiftUI

struct ChildRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ChildDashboardView()
            }
            .tabItem {
                Label("Start", systemImage: "house.fill")
            }

            NavigationStack {
                ChildTasksHomeView()
            }
            .tabItem {
                Label("Zadania", systemImage: "checklist")
            }

            NavigationStack {
                ShopView()
            }
            .tabItem {
                Label("Sklep", systemImage: "bag.fill")
            }

            NavigationStack {
                ChildHistoryHomeView()
            }
            .tabItem {
                Label("Historia", systemImage: "clock.fill")
            }

            NavigationStack {
                ChildProfileView()
            }
            .tabItem {
                Label("Profil", systemImage: "person.crop.circle.fill")
            }
        }
    }
}
