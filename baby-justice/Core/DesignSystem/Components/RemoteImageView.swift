import SwiftUI

struct RemoteImageView: View {
    let path: String

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if failed {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        }
        .clipped()
        .task(id: path) {
            await load()
        }
    }

    private func load() async {
        image = nil
        failed = false
        if let data = await APIClient.shared.fetchImage(path: path),
           let loaded = UIImage(data: data) {
            image = loaded
        } else {
            failed = true
        }
    }
}
