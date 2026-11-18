import SwiftUI

extension View {
    @ViewBuilder
    func bjPinnedHeader<Header: View>(@ViewBuilder _ header: () -> Header) -> some View {
        let content = frame(maxWidth: .infinity, maxHeight: .infinity)
        if #available(iOS 26.0, *) {
            content.safeAreaBar(edge: .top, spacing: 0) {
                header()
            }
        } else {
            content.safeAreaInset(edge: .top, spacing: 0) {
                header()
                    .background(.bar)
            }
        }
    }
}
