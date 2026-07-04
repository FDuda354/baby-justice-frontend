import SwiftUI

struct AvatarView: View {
    let hasAvatar: Bool
    let childId: Int64
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            if hasAvatar {
                RemoteImageView(path: "/api/images/children/\(childId)/avatar")
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.bjPrimary, Color.bjMint)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
