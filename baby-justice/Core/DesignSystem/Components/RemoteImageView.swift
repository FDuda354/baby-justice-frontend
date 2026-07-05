import SwiftUI

struct RemoteImageView: View {
    let path: String

    @State private var image: UIImage?
    @State private var failed = false

    init(path: String) {
        self.path = path
        _image = State(initialValue: ImageCache.shared.image(for: path))
    }

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
        if let cached = ImageCache.shared.image(for: path) {
            image = cached
            failed = false
            return
        }
        image = nil
        failed = false
        if let data = await APIClient.shared.fetchImage(path: path),
           let loaded = UIImage(data: data) {
            ImageCache.shared.store(loaded, for: path)
            image = loaded
        } else {
            failed = true
        }
    }
}
