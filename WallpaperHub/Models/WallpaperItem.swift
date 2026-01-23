import Foundation
import AppKit

struct WallpaperItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var fileURL: URL
    var type: WallpaperType
    var createdDate: Date
    var resolution: String?
    var fileSize: Int64

    enum WallpaperType: String, Codable, CaseIterable {
        case staticImage = "Static Image"
        case animatedImage = "Animated Image"
        case video = "Video"
    }

    init(id: UUID = UUID(), name: String, fileURL: URL, type: WallpaperType, resolution: String? = nil, fileSize: Int64 = 0) {
        self.id = id
        self.name = name
        self.fileURL = fileURL
        self.type = type
        self.createdDate = Date()
        self.resolution = resolution
        self.fileSize = fileSize
    }

    var thumbnail: NSImage? {
        switch type {
        case .staticImage, .animatedImage:
            return NSImage(contentsOf: fileURL)
        case .video:
            return generateVideoThumbnail()
        }
    }

    private func generateVideoThumbnail() -> NSImage? {
        // 動画のサムネイル生成（AVFoundation使用）
        // TODO: 実装
        return nil
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WallpaperItem, rhs: WallpaperItem) -> Bool {
        lhs.id == rhs.id
    }
}
