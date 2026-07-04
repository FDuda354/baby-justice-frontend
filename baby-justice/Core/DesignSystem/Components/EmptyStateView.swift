import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: BJSpacing.m) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(Color.bjPrimary)
                .padding(BJSpacing.l)
                .background(Color.bjMint)
                .clipShape(Circle())
            Text(title)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(BJSpacing.xxl)
    }
}
