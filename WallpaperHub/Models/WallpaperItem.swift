import Foundation
import AppKit

struct WallpaperItem: Identifiable, Hashable {
    let id: UUID
    var name: String
    var fileURL: URL
    var type: WallpaperType
    var createdDate: Date
    var resolution: String?
    var fileSize: Int64
    var wallpaperEngineProject: WallpaperEnginePackage?  // Wallpaper Engineプロジェクト情報

    enum WallpaperType: String, Codable, CaseIterable {
        case staticImage = "Static Image"
        case animatedImage = "Animated Image"
        case video = "Video"
        case wallpaperEngine = "Wallpaper Engine"
    }

    init(id: UUID = UUID(), name: String, fileURL: URL, type: WallpaperType, resolution: String? = nil, fileSize: Int64 = 0, wallpaperEngineProject: WallpaperEnginePackage? = nil) {
        self.id = id
        self.name = name
        self.fileURL = fileURL
        self.type = type
        self.createdDate = Date()
        self.resolution = resolution
        self.fileSize = fileSize
        self.wallpaperEngineProject = wallpaperEngineProject
    }

    var thumbnail: NSImage? {
        switch type {
        case .staticImage, .animatedImage:
            return NSImage(contentsOf: fileURL)
        case .video:
            return generateVideoThumbnail()
        case .wallpaperEngine:
            return generateWallpaperEngineThumbnail()
        }
    }

    private func generateVideoThumbnail() -> NSImage? {
        // 動画のサムネイル生成（AVFoundation使用）
        // TODO: 実装
        return nil
    }

    private func generateWallpaperEngineThumbnail() -> NSImage? {
        // Wallpaper Engineのプレビュー画像を取得
        guard let project = wallpaperEngineProject,
              let previewData = project.getPreviewImage() else {
            return nil
        }
        return NSImage(data: previewData)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WallpaperItem, rhs: WallpaperItem) -> Bool {
        lhs.id == rhs.id
    }
}

// Codable対応
extension WallpaperItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, fileURL, type, createdDate, resolution, fileSize
        // wallpaperEngineProjectは保存時に再読み込みするため除外
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        fileURL = try container.decode(URL.self, forKey: .fileURL)
        type = try container.decode(WallpaperType.self, forKey: .type)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        resolution = try container.decodeIfPresent(String.self, forKey: .resolution)
        fileSize = try container.decode(Int64.self, forKey: .fileSize)
        wallpaperEngineProject = nil  // デコード後に再読み込み
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(fileURL, forKey: .fileURL)
        try container.encode(type, forKey: .type)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encodeIfPresent(resolution, forKey: .resolution)
        try container.encode(fileSize, forKey: .fileSize)
        // wallpaperEngineProjectはエンコードしない
    }
}
