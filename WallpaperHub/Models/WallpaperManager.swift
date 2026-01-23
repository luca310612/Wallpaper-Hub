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
    }

    func addWallpaper(from sourceURL: URL) {
        // ファイルにアクセス
        guard sourceURL.startAccessingSecurityScopedResource() else {
            print("Failed to access file at: \(sourceURL)")
            return
        }
        defer { sourceURL.stopAccessingSecurityScopedResource() }

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

    func removeWallpaper(_ wallpaper: WallpaperItem) {
        // ファイルを削除
        try? fileManager.removeItem(at: wallpaper.fileURL)

        // リストから削除
        wallpapers.removeAll { $0.id == wallpaper.id }
        saveWallpapers()
    }

    func setAsWallpaper(_ wallpaper: WallpaperItem, for screen: NSScreen? = nil) {
        let targetScreen = screen ?? NSScreen.main

        guard let targetScreen = targetScreen else {
            print("No screen available")
            return
        }

        do {
            let workspace = NSWorkspace.shared
            try workspace.setDesktopImageURL(wallpaper.fileURL, for: targetScreen, options: [:])
            print("Wallpaper set successfully for screen: \(targetScreen.localizedName)")
        } catch {
            print("Failed to set wallpaper: \(error.localizedDescription)")
        }
    }

    func setAsWallpaperForAllScreens(_ wallpaper: WallpaperItem) {
        for screen in NSScreen.screens {
            setAsWallpaper(wallpaper, for: screen)
        }
    }

    func refreshWallpapers() {
        loadWallpapers()
    }

    // MARK: - Private Methods

    private func determineWallpaperType(from url: URL) -> WallpaperItem.WallpaperType {
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
            self.wallpapers = loadedWallpapers.filter { self.fileManager.fileExists(atPath: $0.fileURL.path) }
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
}
