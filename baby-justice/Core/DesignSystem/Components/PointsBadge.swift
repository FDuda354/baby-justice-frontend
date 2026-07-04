import SwiftUI

struct PointsBadge: View {
    let points: Int

    var body: some View {
        HStack(spacing: BJSpacing.xs) {
            Image(systemName: "star.circle.fill")
                .foregroundStyle(Color.bjAmber)
            Text("\(points)")
                .fontWeight(.bold)
        }
    }
}
