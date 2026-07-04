import SwiftUI

struct CardView<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(BJSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: BJRadius.card, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
