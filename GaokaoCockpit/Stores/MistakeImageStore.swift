import Foundation
import UIKit

enum MistakeImageStore {
    private static let directoryName = "MistakeImages"
    private static let maxLongSide: CGFloat = 1600
    private static let jpegQuality: CGFloat = 0.82
    private static let imageCache = NSCache<NSString, UIImage>()

    static func saveImage(_ image: UIImage, mistakeId: UUID) throws -> String {
        let directory = try imageDirectory()
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let filename = "mistake-\(mistakeId.uuidString)-\(timestamp).jpg"
        let fileURL = directory.appendingPathComponent(filename)
        let preparedImage = image.resizedForMistakeStorage(maxLongSide: maxLongSide)

        guard let data = preparedImage.jpegData(compressionQuality: jpegQuality) else {
            throw MistakeImageStoreError.encodingFailed
        }

        try data.write(to: fileURL, options: [.atomic])
        imageCache.setObject(preparedImage, forKey: filename as NSString)
        return "\(directoryName)/\(filename)"
    }

    static func saveImageInBackground(_ image: UIImage, mistakeId: UUID) async throws -> String {
        try await Task.detached(priority: .utility) {
            try saveImage(image, mistakeId: mistakeId)
        }.value
    }

    static func saveImageDataInBackground(_ data: Data, mistakeId: UUID) async throws -> String {
        try await Task.detached(priority: .utility) {
            guard let image = UIImage(data: data) else {
                throw MistakeImageStoreError.invalidImageData
            }

            return try saveImage(image, mistakeId: mistakeId)
        }.value
    }

    static func loadImage(path: String) -> UIImage? {
        guard let url = imageURL(path: path) else {
            return nil
        }

        let cacheKey = url.lastPathComponent as NSString
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return cachedImage
        }

        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }

        imageCache.setObject(image, forKey: cacheKey)
        return image
    }

    static func loadImageInBackground(path: String) async -> UIImage? {
        await Task.detached(priority: .utility) {
            loadImage(path: path)
        }.value
    }

    static func deleteImage(path: String) throws {
        guard let url = imageURL(path: path) else {
            return
        }

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }

        try fileManager.removeItem(at: url)
        imageCache.removeObject(forKey: url.lastPathComponent as NSString)
    }

    static func imageURL(path: String) -> URL? {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else {
            return nil
        }

        guard !trimmedPath.hasPrefix("/"), !trimmedPath.contains("://") else {
            return nil
        }

        let filename = URL(fileURLWithPath: trimmedPath).lastPathComponent
        guard !filename.isEmpty, filename != "." else {
            return nil
        }

        return try? imageDirectory().appendingPathComponent(filename)
    }

    private static func imageDirectory() throws -> URL {
        let fileManager = FileManager.default
        guard let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw MistakeImageStoreError.applicationSupportUnavailable
        }

        let directory = applicationSupportURL.appendingPathComponent(directoryName, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

enum MistakeImageStoreError: LocalizedError {
    case applicationSupportUnavailable
    case invalidImageData
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .applicationSupportUnavailable:
            return "无法访问 Application Support 目录。"
        case .invalidImageData:
            return "图片格式无法读取。"
        case .encodingFailed:
            return "图片压缩失败。"
        }
    }
}

private extension UIImage {
    func resizedForMistakeStorage(maxLongSide: CGFloat) -> UIImage {
        let longSide = max(size.width, size.height)
        guard longSide > maxLongSide else {
            return self
        }

        let scaleRatio = maxLongSide / longSide
        let targetSize = CGSize(
            width: size.width * scaleRatio,
            height: size.height * scaleRatio
        )
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
