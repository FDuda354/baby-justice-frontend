import SwiftUI

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: BJSize.buttonHeight)
                .background(Color.bjMint)
                .foregroundStyle(Color.bjPrimaryDark)
                .clipShape(RoundedRectangle(cornerRadius: BJRadius.button, style: .continuous))
        }
    }
}
