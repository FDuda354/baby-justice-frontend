import SwiftUI

private enum RootScreen: Equatable {
    case landing
    case parent
    case child
}

struct RootView: View {
    private var session: SessionStore { SessionStore.shared }

    var body: some View {
        ZStack {
            switch screen {
            case .landing:
                LandingView()
                    .transition(.opacity)
            case .parent:
                ParentRootView()
                    .transition(.opacity)
            case .child:
                ChildRootView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: screen)
    }

    private var screen: RootScreen {
        guard session.token != nil, let role = session.role else { return .landing }
        return role == .parent ? .parent : .child
    }
}
