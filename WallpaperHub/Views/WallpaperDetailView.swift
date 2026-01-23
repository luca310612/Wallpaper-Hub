import SwiftUI
import AVKit

struct WallpaperDetailView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    let wallpaper: WallpaperItem
    @State private var showingDeleteAlert = false
    @State private var selectedScreen: NSScreen?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // プレビュー
                wallpaperPreview
                    .frame(maxHeight: 400)

                // 情報カード
                VStack(alignment: .leading, spacing: 16) {
                    // タイトル
                    Text(wallpaper.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Divider()

                    // 詳細情報
                    InfoRow(label: "Type", value: wallpaper.type.rawValue)

                    if let resolution = wallpaper.resolution {
                        InfoRow(label: "Resolution", value: resolution)
                    }

                    InfoRow(label: "File Size", value: formatFileSize(wallpaper.fileSize))

                    InfoRow(label: "Added", value: formatDate(wallpaper.createdDate))

                    InfoRow(label: "Location", value: wallpaper.fileURL.path)

                    Divider()

                    // アクションボタン
                    VStack(spacing: 12) {
                        // すべてのディスプレイに設定
                        Button(action: {
                            wallpaperManager.setAsWallpaperForAllScreens(wallpaper)
                        }) {
                            HStack {
                                Image(systemName: "display.2")
                                Text("Set for All Displays")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        // 個別ディスプレイに設定
                        if NSScreen.screens.count > 1 {
                            Menu {
                                ForEach(NSScreen.screens.indices, id: \.self) { index in
                                    Button("Display \(index + 1)") {
                                        wallpaperManager.setAsWallpaper(wallpaper, for: NSScreen.screens[index])
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "display")
                                    Text("Set for Specific Display")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }

                        // Finderで表示
                        Button(action: {
                            NSWorkspace.shared.activateFileViewerSelecting([wallpaper.fileURL])
                        }) {
                            HStack {
                                Image(systemName: "folder")
                                Text("Show in Finder")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                        // 削除
                        Button(role: .destructive, action: {
                            showingDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Wallpaper")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .alert("Delete Wallpaper", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                wallpaperManager.removeWallpaper(wallpaper)
            }
        } message: {
            Text("Are you sure you want to delete \"\(wallpaper.name)\"? This action cannot be undone.")
        }
    }

    @ViewBuilder
    private var wallpaperPreview: some View {
        switch wallpaper.type {
        case .staticImage, .animatedImage:
            if let image = wallpaper.thumbnail {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(radius: 10)
            }
        case .video:
            VideoPlayer(player: AVPlayer(url: wallpaper.fileURL))
                .aspectRatio(16/9, contentMode: .fit)
                .cornerRadius(12)
                .shadow(radius: 10)
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .textSelection(.enabled)

            Spacer()
        }
    }
}
