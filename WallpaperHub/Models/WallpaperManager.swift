import Foundation
import AppKit
import AVFoundation
import UniformTypeIdentifiers

class WallpaperManager: ObservableObject {
    static let shared = WallpaperManager()

    @Published var wallpapers: [WallpaperItem] = []

    private let fileManager = FileManager.default
    private let wallpapersDirectory: URL

    private init() {
        // アプリのサポートディレクトリに壁紙を保存
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        wallpapersDirectory = appSupportURL.appendingPathComponent("WallpaperHub/Wallpapers")

        // ディレクトリを作成
        try? fileManager.createDirectory(at: wallpapersDirectory, withIntermediateDirectories: true)

        // 保存されている壁紙を読み込み
        loadWallpapers()

        // バンドル内のwallpaper_imageディレクトリから壁紙を読み込み
        loadBundledWallpapers()
    }

    func addWallpaper(from sourceURL: URL) {
        // ファイルにアクセス
        guard sourceURL.startAccessingSecurityScopedResource() else {
            print("Failed to access file at: \(sourceURL)")
            return
        }
        defer { sourceURL.stopAccessingSecurityScopedResource() }

        // Wallpaper Engineフォルダかチェック
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory),
           isDirectory.boolValue,
           WallpaperEngineParser.isWallpaperEngineFolder(at: sourceURL) {
            addWallpaperEngineProject(from: sourceURL)
            return
        }

        // ファイルタイプを判定
        let type = determineWallpaperType(from: sourceURL)

        // ファイル名と保存先を決定
        let fileName = sourceURL.lastPathComponent
        let destinationURL = wallpapersDirectory.appendingPathComponent(fileName)

        do {
            // ファイルをコピー
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)

            // ファイルサイズを取得
            let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0

            // 解像度を取得
            let resolution = getResolution(from: destinationURL, type: type)

            // 壁紙アイテムを作成
            let wallpaper = WallpaperItem(
                name: fileName,
                fileURL: destinationURL,
                type: type,
                resolution: resolution,
                fileSize: fileSize
            )

            // リストに追加
            DispatchQueue.main.async {
                self.wallpapers.append(wallpaper)
                self.saveWallpapers()
            }

            print("Wallpaper added: \(fileName)")
        } catch {
            print("Failed to add wallpaper: \(error.localizedDescription)")
        }
    }

    func addWallpaperEngineProject(from sourceURL: URL) {
        do {
            // Wallpaper Engineプロジェクトを読み込み（検証用）
            _ = try WallpaperEngineParser.loadProject(at: sourceURL)

            // フォルダ名を取得
            let folderName = sourceURL.lastPathComponent
            let destinationURL = wallpapersDirectory.appendingPathComponent(folderName)

            // フォルダをコピー
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)

            // フォルダサイズを取得
            let folderSize = try getFolderSize(at: destinationURL)

            // プロジェクトを再読み込み（コピー先から）
            let copiedPackage = try WallpaperEngineParser.loadProject(at: destinationURL)

            // 解像度を取得（orthogonalprojectionから）
            var resolution: String?
            if let ortho = copiedPackage.project.general?.properties?["orthogonalprojection"],
               let width = ortho.value?.stringValue.split(separator: " ").first,
               let height = ortho.value?.stringValue.split(separator: " ").last {
                resolution = "\(width) × \(height)"
            }

            // 壁紙アイテムを作成
            let wallpaper = WallpaperItem(
                name: copiedPackage.name,
                fileURL: destinationURL,
                type: .wallpaperEngine,
                resolution: resolution,
                fileSize: folderSize,
                wallpaperEngineProject: copiedPackage
            )

            // リストに追加
            DispatchQueue.main.async {
                self.wallpapers.append(wallpaper)
                self.saveWallpapers()
            }

            print("Wallpaper Engine project added: \(copiedPackage.name)")
        } catch {
            print("Failed to add Wallpaper Engine project: \(error.localizedDescription)")
        }
    }

    func addBundledWallpaperEngineProject(from sourceURL: URL) {
        do {
            // Wallpaper Engineプロジェクトを読み込み
            let package = try WallpaperEngineParser.loadProject(at: sourceURL)

            // フォルダサイズを取得
            let folderSize = try getFolderSize(at: sourceURL)

            // 解像度を取得（orthogonalprojectionから）
            var resolution: String?
            if let ortho = package.project.general?.properties?["orthogonalprojection"],
               let width = ortho.value?.stringValue.split(separator: " ").first,
               let height = ortho.value?.stringValue.split(separator: " ").last {
                resolution = "\(width) × \(height)"
            }

            // 壁紙アイテムを作成（コピーせずに元のURLを参照）
            let wallpaper = WallpaperItem(
                name: package.name,
                fileURL: sourceURL,
                type: .wallpaperEngine,
                resolution: resolution,
                fileSize: folderSize,
                wallpaperEngineProject: package
            )

            // リストに追加
            DispatchQueue.main.async {
                self.wallpapers.append(wallpaper)
            }

            print("Bundled Wallpaper Engine project loaded: \(package.name)")
        } catch {
            print("Failed to load bundled Wallpaper Engine project: \(error.localizedDescription)")
        }
    }

    func removeWallpaper(_ wallpaper: WallpaperItem) {
        // ファイルを削除
        try? fileManager.removeItem(at: wallpaper.fileURL)

        // リストから削除
        wallpapers.removeAll { $0.id == wallpaper.id }
        saveWallpapers()
    }

    func setAsWallpaper(_ wallpaper: WallpaperItem, for screen: NSScreen? = nil) -> Bool {
        // Wallpaper Engineの場合はプレビュー画像を使用
        if wallpaper.type == .wallpaperEngine,
           let project = wallpaper.wallpaperEngineProject,
           let previewURL = project.previewURL {
            let success = setWallpaperUsingAppleScript(previewURL)
            if success {
                print("Wallpaper Engine preview set successfully: \(wallpaper.name)")
            } else {
                print("Failed to set Wallpaper Engine preview: \(wallpaper.name)")
            }
            return success
        }

        let success = setWallpaperUsingAppleScript(wallpaper.fileURL)

        if success {
            print("Wallpaper set successfully: \(wallpaper.name)")
        } else {
            print("Failed to set wallpaper: \(wallpaper.name)")
        }

        return success
    }

    func setAsWallpaperForAllScreens(_ wallpaper: WallpaperItem) -> Bool {
        // Wallpaper Engineの場合はプレビュー画像を使用
        if wallpaper.type == .wallpaperEngine,
           let project = wallpaper.wallpaperEngineProject,
           let previewURL = project.previewURL {
            return setWallpaperUsingAppleScript(previewURL, allScreens: true)
        }

        return setWallpaperUsingAppleScript(wallpaper.fileURL, allScreens: true)
    }

    // MARK: - AppleScript Integration

    private func setWallpaperUsingAppleScript(_ imageURL: URL, allScreens: Bool = false) -> Bool {
        // ファイルが存在するか確認
        guard fileManager.fileExists(atPath: imageURL.path) else {
            print("❌ File does not exist at path: \(imageURL.path)")
            return false
        }

        // POSIXパスを取得（エスケープ処理）
        let imagePath = imageURL.path.replacingOccurrences(of: "\"", with: "\\\"")

        print("=== Setting Wallpaper ===")
        print("Image path: \(imagePath)")
        print("All screens: \(allScreens)")
        print("File exists: \(fileManager.fileExists(atPath: imageURL.path))")

        // AppleScriptを作成
        let script: String
        if allScreens {
            // すべてのデスクトップに設定
            script = """
            tell application "System Events"
                tell every desktop
                    set picture to POSIX file "\(imagePath)"
                end tell
            end tell
            """
        } else {
            // 現在のデスクトップに設定
            script = """
            tell application "System Events"
                tell current desktop
                    set picture to POSIX file "\(imagePath)"
                end tell
            end tell
            """
        }

        print("AppleScript:\n\(script)")

        // AppleScriptを実行
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)

            if let error = error {
                print("❌ AppleScript error: \(error)")

                // より詳細なエラー情報を表示
                if let errorNumber = error["NSAppleScriptErrorNumber"] as? Int {
                    print("Error number: \(errorNumber)")
                }
                if let errorMessage = error["NSAppleScriptErrorMessage"] as? String {
                    print("Error message: \(errorMessage)")
                }

                return false
            }

            print("✅ AppleScript executed successfully")
            print("Output: \(output)")

            // 設定が実際に適用されたか確認
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.verifyWallpaperSet(imagePath: imagePath)
            }

            return true
        }

        print("❌ Failed to create AppleScript object")
        return false
    }

    private func verifyWallpaperSet(imagePath: String) {
        let verifyScript = """
        tell application "System Events"
            tell current desktop
                get picture
            end tell
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: verifyScript) {
            let output = scriptObject.executeAndReturnError(&error)

            if error == nil {
                print("Current wallpaper path: \(output.stringValue ?? "unknown")")
            }
        }
    }

    func refreshWallpapers() {
        loadWallpapers()
    }

    // MARK: - Private Methods

    private func determineWallpaperType(from url: URL) -> WallpaperItem.WallpaperType {
        // ディレクトリの場合、Wallpaper Engineかチェック
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
           isDirectory.boolValue {
            if WallpaperEngineParser.isWallpaperEngineFolder(at: url) {
                return .wallpaperEngine
            }
        }

        let pathExtension = url.pathExtension.lowercased()

        let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v"]
        let animatedExtensions = ["gif", "apng"]

        if videoExtensions.contains(pathExtension) {
            return .video
        } else if animatedExtensions.contains(pathExtension) {
            return .animatedImage
        } else {
            return .staticImage
        }
    }

    private func getFolderSize(at url: URL) throws -> Int64 {
        var totalSize: Int64 = 0
        let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey])

        while let fileURL = enumerator?.nextObject() as? URL {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                totalSize += fileSize
            }
        }

        return totalSize
    }

    private func getResolution(from url: URL, type: WallpaperItem.WallpaperType) -> String? {
        switch type {
        case .staticImage, .animatedImage:
            if let image = NSImage(contentsOf: url) {
                let size = image.size
                return "\(Int(size.width)) × \(Int(size.height))"
            }
        case .video:
            let asset = AVAsset(url: url)
            if let track = asset.tracks(withMediaType: .video).first {
                let size = track.naturalSize
                return "\(Int(size.width)) × \(Int(size.height))"
            }
        case .wallpaperEngine:
            return nil  // 解像度は addWallpaperEngineProject で orthogonalprojection から取得
        }
        return nil
    }

    private func loadWallpapers() {
        // メタデータファイルから読み込み
        let metadataURL = wallpapersDirectory.appendingPathComponent("metadata.json")

        guard fileManager.fileExists(atPath: metadataURL.path),
              let data = try? Data(contentsOf: metadataURL),
              let loadedWallpapers = try? JSONDecoder().decode([WallpaperItem].self, from: data) else {
            // メタデータがない場合は空のリストで開始
            return
        }

        DispatchQueue.main.async {
            // ファイルが存在するものだけをフィルタリング
            let validWallpapers = loadedWallpapers.filter { self.fileManager.fileExists(atPath: $0.fileURL.path) }

            // Wallpaper Engineプロジェクトを再読み込み
            self.wallpapers = validWallpapers.map { wallpaper in
                var updatedWallpaper = wallpaper
                if wallpaper.type == .wallpaperEngine {
                    if let package = try? WallpaperEngineParser.loadProject(at: wallpaper.fileURL) {
                        updatedWallpaper.wallpaperEngineProject = package
                    }
                }
                return updatedWallpaper
            }
        }
    }

    private func saveWallpapers() {
        let metadataURL = wallpapersDirectory.appendingPathComponent("metadata.json")

        do {
            let data = try JSONEncoder().encode(wallpapers)
            try data.write(to: metadataURL)
        } catch {
            print("Failed to save wallpapers: \(error.localizedDescription)")
        }
    }

    private func loadBundledWallpapers() {
        print("=== Loading bundled wallpapers ===")

        // 複数の場所からwallpaper_imageディレクトリを探す
        var searchURLs: [URL] = []

        // 1. バンドル内のResourcesフォルダ
        if let resourceURL = Bundle.main.resourceURL {
            searchURLs.append(resourceURL.appendingPathComponent("wallpaper_image"))
            print("Searching in bundle resources: \(resourceURL.appendingPathComponent("wallpaper_image").path)")
        }

        // 2. ソースコードと同じディレクトリ（開発中用）
        let sourceURL = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        searchURLs.append(sourceURL.appendingPathComponent("WallpaperHub/wallpaper_image"))
        print("Searching in source directory: \(sourceURL.appendingPathComponent("WallpaperHub/wallpaper_image").path)")

        var foundDirectory: URL?
        for searchURL in searchURLs {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: searchURL.path, isDirectory: &isDirectory),
               isDirectory.boolValue {
                foundDirectory = searchURL
                print("✓ Found wallpaper_image at: \(searchURL.path)")
                break
            } else {
                print("✗ Not found at: \(searchURL.path)")
            }
        }

        guard let bundleURL = foundDirectory else {
            print("❌ wallpaper_image directory not found in any search location")
            return
        }

        // ディレクトリ内のすべてのサブディレクトリを探索
        do {
            let contents = try fileManager.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)

            for itemURL in contents {
                var itemIsDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: itemURL.path, isDirectory: &itemIsDirectory),
                      itemIsDirectory.boolValue else {
                    continue
                }

                // Wallpaper Engineプロジェクトかチェック
                if WallpaperEngineParser.isWallpaperEngineFolder(at: itemURL) {
                    // 既に追加済みかチェック（ファイルパスで判定）
                    let alreadyExists = wallpapers.contains { wallpaper in
                        wallpaper.fileURL.path == itemURL.path
                    }

                    if !alreadyExists {
                        // まだ追加されていない場合は追加（コピーせずに参照）
                        addBundledWallpaperEngineProject(from: itemURL)
                    }
                }
            }
        } catch {
            print("Failed to read wallpaper_image directory: \(error.localizedDescription)")
        }
    }
}
