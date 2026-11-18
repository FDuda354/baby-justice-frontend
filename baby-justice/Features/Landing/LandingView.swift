import SwiftUI

enum AuthRoute: Hashable {
    case login
    case register
    case forgotPassword
}

struct LandingView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var viewModel = AuthViewModel()
    @State private var path: [AuthRoute] = []
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 42

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LinearGradient(
                    colors: [Color.bjPrimary, Color.bjPrimaryDark],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                GeometryReader { geometry in
                    let usesColumns = horizontalSizeClass == .regular
                        && geometry.size.width >= 700
                        && !dynamicTypeSize.isAccessibilitySize
                    let layout = usesColumns
                        ? AnyLayout(HStackLayout(alignment: .center, spacing: BJSpacing.xxl))
                        : AnyLayout(VStackLayout(spacing: BJSpacing.xxl))

                    ScrollView {
                        layout {
                            hero
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            actionPanel
                                .frame(maxWidth: usesColumns ? 360 : .infinity)
                        }
                        .padding(BJSpacing.xl)
                        .frame(maxWidth: usesColumns ? 1080 : 520)
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: AuthRoute.self) { route in
                destination(for: route)
            }
        }
        .tint(Color.bjAccent)
    }

    private var hero: some View {
        VStack(spacing: BJSpacing.xl) {
            symbolComposition
            VStack(spacing: BJSpacing.s) {
                Text("Baby Justice")
                    .font(.system(size: titleSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Rodzinne zadania, uczciwe punkty i nagrody, na które warto zapracować.")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, BJSpacing.xl)
    }

    private var symbolComposition: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 176, height: 176)
            Image(systemName: "figure.2.and.child.holdinghands")
                .font(.system(size: 78, weight: .medium))
                .foregroundStyle(.white)
            Image(systemName: "star.circle.fill")
                .font(.system(size: 42))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, Color.bjAmber)
                .offset(x: 72, y: -62)
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 34))
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.bjPrimaryDark, .white)
                .offset(x: -74, y: 58)
        }
    }

    private var actionPanel: some View {
        VStack(spacing: BJSpacing.m) {
            PrimaryButton(title: "Zaloguj się") {
                path.append(.login)
            }
            SecondaryButton(title: "Zarejestruj się") {
                path.append(.register)
            }
        }
        .padding(BJSpacing.l)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }

    @ViewBuilder
    private func destination(for route: AuthRoute) -> some View {
        switch route {
        case .login:
            LoginView(viewModel: viewModel)
        case .register:
            RegisterView(viewModel: viewModel)
        case .forgotPassword:
            ForgotPasswordView(viewModel: viewModel)
        }
    }
}
