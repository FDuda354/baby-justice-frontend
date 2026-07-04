import UIKit

enum AvatarImageProcessor {
    static func downscaledJpegData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maxDimension: CGFloat = 800
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let largestSide = max(pixelWidth, pixelHeight)
        let scale = min(1, maxDimension / largestSide)
        let targetSize = CGSize(width: pixelWidth * scale, height: pixelHeight * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}
