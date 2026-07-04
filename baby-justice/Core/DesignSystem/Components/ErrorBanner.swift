import SwiftUI

struct ErrorBanner: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: BJSpacing.m) {
            HStack(alignment: .top, spacing: BJSpacing.s) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.bjDanger)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button(action: retry) {
                Label("Spróbuj ponownie", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.bjPrimaryDark)
            }
        }
        .padding(BJSpacing.l)
        .frame(maxWidth: .infinity)
        .background(Color.bjDanger.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: BJRadius.card, style: .continuous))
        .padding(.horizontal, BJSpacing.l)
    }
}
