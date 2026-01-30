import Foundation

// Wallpaper Engineのプロジェクトファイル（project.json）の構造
struct WallpaperEngineProject: Codable {
    let contentrating: String?
    let description: String?
    let file: String  // scene.json等のシーンファイル名
    let general: GeneralProperties?
    let preview: String?  // プレビュー画像/GIF
    let tags: [String]?
    let title: String
    let type: String  // "Scene", "Video", "Web"等
    let version: Int?
    let workshopid: String?
    let workshopurl: String?

    struct GeneralProperties: Codable {
        let properties: [String: Property]?
        let supportsaudioprocessing: Bool?
        let supportsvideo: Bool?
        let supportsvideoflags: Int?
    }

    struct Property: Codable {
        let index: Int?
        let order: Int?
        let text: String?
        let type: String?  // "slider", "combo", "bool", "color"等
        let value: PropertyValue?

        // slider用のプロパティ
        let fraction: Bool?
        let max: Double?
        let min: Double?
        let precision: Int?
        let step: Double?

        // combo用のプロパティ
        let options: [ComboOption]?

        // カスタムデコーディング
        enum CodingKeys: String, CodingKey {
            case index, order, text, type, value
            case fraction, max, min, precision, step
            case options
        }
    }

    struct ComboOption: Codable {
        let label: String
        let value: String
    }

    // プロパティの値は文字列、数値、真偽値のいずれか
    enum PropertyValue: Codable {
        case string(String)
        case int(Int)
        case double(Double)
        case bool(Bool)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let boolValue = try? container.decode(Bool.self) {
                self = .bool(boolValue)
            } else if let intValue = try? container.decode(Int.self) {
                self = .int(intValue)
            } else if let doubleValue = try? container.decode(Double.self) {
                self = .double(doubleValue)
            } else if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else {
                throw DecodingError.typeMismatch(
                    PropertyValue.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Expected String, Int, Double, or Bool"
                    )
                )
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value):
                try container.encode(value)
            case .int(let value):
                try container.encode(value)
            case .double(let value):
                try container.encode(value)
            case .bool(let value):
                try container.encode(value)
            }
        }

        var stringValue: String {
            switch self {
            case .string(let value): return value
            case .int(let value): return String(value)
            case .double(let value): return String(value)
            case .bool(let value): return String(value)
            }
        }

        var doubleValue: Double? {
            switch self {
            case .double(let value): return value
            case .int(let value): return Double(value)
            default: return nil
            }
        }

        var boolValue: Bool? {
            switch self {
            case .bool(let value): return value
            default: return nil
            }
        }
    }
}

// Wallpaper Engineのシーンファイル（scene.json）の基本構造
struct WallpaperEngineScene: Codable {
    let objects: [SceneObject]?
    let orthogonalprojection: OrthogonalProjection?
    let camera: Camera?

    struct SceneObject: Codable {
        let name: String?
        let origin: String?
        let scale: String?
        let angles: String?
        let visible: Bool?
        let image: String?
        let material: String?
        let effects: [Effect]?
    }

    struct Effect: Codable {
        let file: String
    }

    struct OrthogonalProjection: Codable {
        let width: Int?
        let height: Int?
    }

    struct Camera: Codable {
        let center: [Double]?
        let eye: [Double]?
        let up: [Double]?
    }
}

// Wallpaper Engineのパッケージ情報
struct WallpaperEnginePackage: Codable, Hashable {
    let projectURL: URL
    let scenePackageURL: URL
    let previewURL: URL?
    let project: WallpaperEngineProject

    init(directoryURL: URL) throws {
        // project.jsonを読み込み
        let projectURL = directoryURL.appendingPathComponent("project.json")
        guard let projectData = try? Data(contentsOf: projectURL) else {
            throw WallpaperEngineError.projectFileNotFound
        }

        let decoder = JSONDecoder()
        self.project = try decoder.decode(WallpaperEngineProject.self, from: projectData)

        self.projectURL = projectURL
        self.scenePackageURL = directoryURL.appendingPathComponent("scene.pkg")

        // プレビュー画像を探す
        if let previewName = project.preview {
            let previewURL = directoryURL.appendingPathComponent(previewName)
            self.previewURL = FileManager.default.fileExists(atPath: previewURL.path) ? previewURL : nil
        } else {
            self.previewURL = nil
        }
    }

    // Codable用のイニシャライザ
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectURL = try container.decode(URL.self, forKey: .projectURL)
        scenePackageURL = try container.decode(URL.self, forKey: .scenePackageURL)
        previewURL = try container.decodeIfPresent(URL.self, forKey: .previewURL)
        project = try container.decode(WallpaperEngineProject.self, forKey: .project)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectURL, forKey: .projectURL)
        try container.encode(scenePackageURL, forKey: .scenePackageURL)
        try container.encodeIfPresent(previewURL, forKey: .previewURL)
        try container.encode(project, forKey: .project)
    }

    enum CodingKeys: String, CodingKey {
        case projectURL, scenePackageURL, previewURL, project
    }

    var name: String {
        project.title
    }

    var wallpaperType: String {
        project.type
    }

    var workshopID: String? {
        project.workshopid
    }

    // Hashable対応
    func hash(into hasher: inout Hasher) {
        hasher.combine(projectURL)
        hasher.combine(scenePackageURL)
    }

    static func == (lhs: WallpaperEnginePackage, rhs: WallpaperEnginePackage) -> Bool {
        lhs.projectURL == rhs.projectURL && lhs.scenePackageURL == rhs.scenePackageURL
    }
}

enum WallpaperEngineError: Error, LocalizedError {
    case projectFileNotFound
    case scenePackageNotFound
    case invalidFormat
    case unsupportedType

    var errorDescription: String? {
        switch self {
        case .projectFileNotFound:
            return "project.json file not found"
        case .scenePackageNotFound:
            return "scene.pkg file not found"
        case .invalidFormat:
            return "Invalid Wallpaper Engine format"
        case .unsupportedType:
            return "Unsupported wallpaper type"
        }
    }
}
