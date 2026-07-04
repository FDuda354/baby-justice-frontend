import SwiftUI

struct ParentMoreView: View {
    @State private var showLogoutConfirmation = false

    var body: some View {
        List {
            Section {
                NavigationLink {
                    ParentHistoryView()
                } label: {
                    Label("Historia", systemImage: "clock.arrow.circlepath")
                }
                NavigationLink {
                    ParentNotificationsView()
                } label: {
                    Label("Powiadomienia", systemImage: "bell.fill")
                }
                NavigationLink {
                    ParentSettingsView()
                } label: {
                    Label("Ustawienia", systemImage: "gearshape.fill")
                }
            }

            Section {
                Button(role: .destructive) {
                    showLogoutConfirmation = true
                } label: {
                    Label("Wyloguj się", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Więcej")
        .confirmationDialog(
            "Czy na pewno chcesz się wylogować?",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Wyloguj się", role: .destructive) {
                SessionStore.shared.logout()
            }
            Button("Anuluj", role: .cancel) {}
        }
    }
}
