import SwiftUI

struct BJScrollView<Content: View>: View {
    var maxWidth: CGFloat = 720
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                content()
            }
            .bjReadableWidth(maxWidth: maxWidth)
        }
    }
}

extension View {
    func bjReadableWidth(maxWidth: CGFloat = 720) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}
