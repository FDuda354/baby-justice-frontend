import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var background: Color = .bjPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: BJSize.buttonHeight)
            .background(background)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: BJRadius.button, style: .continuous))
        }
        .disabled(isLoading)
    }
}
