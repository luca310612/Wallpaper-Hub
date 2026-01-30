import Foundation
import Compression

// Wallpaper Engineのscene.pkgファイルを解析するパーサー
class WallpaperEngineParser {

    // scene.pkgのヘッダー構造
    struct PackageHeader {
        let magic: UInt32  // "PKGV"
        let version: UInt32
        let fileCount: UInt32
    }

    // パッケージ内のファイル情報
    struct PackageFile {
        let name: String
        let offset: UInt64
        let size: UInt64
        let compressedSize: UInt64
        let isCompressed: Bool
    }

    // scene.pkgからファイル一覧を取得
    static func parsePackage(at url: URL) throws -> [PackageFile] {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            throw WallpaperEngineError.scenePackageNotFound
        }
        defer { try? fileHandle.close() }

        let files: [PackageFile] = []

        // ヘッダーを読み込み（とりあえずスキップして内容を探索）
        // Wallpaper Engineのパッケージは独自フォーマットなので、
        // 完全な解析には詳細な仕様が必要

        return files
    }

    // scene.pkgから特定のファイルを抽出
    static func extractFile(_ file: PackageFile, from packageURL: URL) throws -> Data {
        guard let fileHandle = try? FileHandle(forReadingFrom: packageURL) else {
            throw WallpaperEngineError.scenePackageNotFound
        }
        defer { try? fileHandle.close() }

        // ファイルオフセットまでシーク
        fileHandle.seek(toFileOffset: file.offset)

        // データを読み込み
        let data = fileHandle.readData(ofLength: Int(file.compressedSize))

        // 圧縮されている場合は解凍
        if file.isCompressed {
            return try decompress(data)
        }

        return data
    }

    // scene.jsonを抽出（scene.pkgから）
    static func extractSceneJSON(from packageURL: URL) throws -> WallpaperEngineScene? {
        // scene.pkgは複雑なバイナリフォーマットのため、
        // 実際の解析には詳細な仕様が必要
        // ここでは基本的な構造を定義
        return nil
    }

    // データを解凍（LZFSE）
    private static func decompress(_ data: Data) throws -> Data {
        do {
            return try (data as NSData).decompressed(using: .lzfse) as Data
        } catch {
            throw WallpaperEngineError.invalidFormat
        }
    }

    // Wallpaper Engineフォルダかどうかを判定
    static func isWallpaperEngineFolder(at url: URL) -> Bool {
        let fileManager = FileManager.default

        // project.jsonとscene.pkgの存在をチェック
        let projectURL = url.appendingPathComponent("project.json")
        let scenePkgURL = url.appendingPathComponent("scene.pkg")

        return fileManager.fileExists(atPath: projectURL.path) &&
               fileManager.fileExists(atPath: scenePkgURL.path)
    }

    // Wallpaper Engineプロジェクトをロード
    static func loadProject(at url: URL) throws -> WallpaperEnginePackage {
        return try WallpaperEnginePackage(directoryURL: url)
    }
}

// プレビュー生成用のヘルパー
extension WallpaperEnginePackage {

    // プレビュー画像を取得
    func getPreviewImage() -> Data? {
        guard let previewURL = previewURL else { return nil }
        return try? Data(contentsOf: previewURL)
    }

    // プロジェクト情報のサマリー
    var summary: String {
        var info = "Name: \(name)\n"
        info += "Type: \(wallpaperType)\n"

        if let workshopID = workshopID {
            info += "Workshop ID: \(workshopID)\n"
        }

        if let description = project.description {
            info += "Description: \(description)\n"
        }

        return info
    }

    // 設定可能なプロパティを取得
    var configurableProperties: [String: WallpaperEngineProject.Property] {
        return project.general?.properties ?? [:]
    }
}
