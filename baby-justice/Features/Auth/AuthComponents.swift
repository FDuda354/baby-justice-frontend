import SwiftUI

struct AuthHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: BJSpacing.m) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(Color.bjPrimary)
                .padding(BJSpacing.l)
                .background(Color.bjMint)
                .clipShape(Circle())
            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AuthRolePicker: View {
    @Binding var selectedRole: Role

    var body: some View {
        Picker("Rola", selection: $selectedRole) {
            ForEach(Role.allCases, id: \.self) { role in
                Text(role.displayName).tag(role)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct AuthErrorLabel: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: BJSpacing.s) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color.bjDanger)
            Text(message)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.bjDanger)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(BJSpacing.m)
        .background(Color.bjDanger.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: BJRadius.field, style: .continuous))
    }
}
