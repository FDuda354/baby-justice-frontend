import SwiftUI

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, BJSpacing.l)
                .padding(.vertical, BJSpacing.m)
                .frame(maxWidth: .infinity)
                .frame(minHeight: BJSize.buttonHeight)
                .background(Color.bjMint)
                .foregroundStyle(Color.bjAccent)
                .clipShape(RoundedRectangle(cornerRadius: BJRadius.button, style: .continuous))
        }
    }
}
