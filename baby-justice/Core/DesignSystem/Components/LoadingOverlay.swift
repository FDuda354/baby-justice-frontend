import SwiftUI

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.15)
                .ignoresSafeArea()
            ProgressView()
                .controlSize(.large)
                .padding(BJSpacing.xl)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: BJRadius.card, style: .continuous))
        }
    }
}
