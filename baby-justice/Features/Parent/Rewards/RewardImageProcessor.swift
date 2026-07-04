import UIKit

enum RewardImageProcessor {
    static let contentType = "image/jpeg"

    static func processedJpegData(from data: Data, maxDimension: CGFloat = 800) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }
        let scale = min(1, maxDimension / max(pixelWidth, pixelHeight))
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
