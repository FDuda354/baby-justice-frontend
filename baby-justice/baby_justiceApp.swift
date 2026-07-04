import SwiftUI

@main
struct baby_justiceApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(SessionStore.shared)
                .tint(.bjPrimary)
        }
    }
}
