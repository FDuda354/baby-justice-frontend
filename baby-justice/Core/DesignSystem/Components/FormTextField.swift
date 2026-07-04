import SwiftUI

struct FormTextField: View {
    let label: String
    @Binding var text: String
    var secure: Bool = false
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: BJSpacing.xs) {
            Text(label)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            field
                .padding(.horizontal, BJSpacing.m)
                .frame(height: BJSize.fieldHeight)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: BJRadius.field, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: BJRadius.field, style: .continuous)
                        .strokeBorder(Color.bjPrimary.opacity(0.2), lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private var field: some View {
        if secure {
            SecureField("", text: $text)
        } else {
            TextField("", text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .sentences)
                .autocorrectionDisabled(keyboard == .emailAddress)
        }
    }
}
