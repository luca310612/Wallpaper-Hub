import SwiftUI

struct ContentView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @State private var selectedWallpaper: WallpaperItem?
    @State private var showingFilePicker = false
    @State private var searchText = ""

    private let gridColumns = [
        GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
    ]

    var filteredWallpapers: [WallpaperItem] {
        if searchText.isEmpty {
            return wallpaperManager.wallpapers
        } else {
            return wallpaperManager.wallpapers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // メインコンテンツ（壁紙グリッド）
            VStack(spacing: 0) {
                // ツールバー
                HStack {
                    // 検索バー
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search wallpapers", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    .frame(maxWidth: 300)

                    Spacer()

                    // 追加ボタン
                    Button(action: { showingFilePicker = true }) {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)

                    Button(action: { wallpaperManager.refreshWallpapers() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor))

                Divider()

                // 壁紙グリッド
                if wallpaperManager.wallpapers.isEmpty {
                    DropZoneView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: gridColumns, spacing: 16) {
                            ForEach(filteredWallpapers) { wallpaper in
                                WallpaperGridItem(
                                    wallpaper: wallpaper,
                                    isSelected: selectedWallpaper?.id == wallpaper.id
                                )
                                .onTapGesture {
                                    selectedWallpaper = wallpaper
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                }
            }

            // 右サイドバー（選択時のみ表示）
            if let wallpaper = selectedWallpaper {
                Divider()
                WallpaperSidebarView(wallpaper: wallpaper, selectedWallpaper: $selectedWallpaper)
                    .frame(width: 320)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.image, .movie, .folder],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result: result)
        }
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                wallpaperManager.addWallpaper(from: url)
            }
        case .failure(let error):
            print("File import error: \(error.localizedDescription)")
        }
    }
}

struct WallpaperGridItem: View {
    let wallpaper: WallpaperItem
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // サムネイル
            ZStack {
                if let thumbnail = wallpaper.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 140)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 140)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        )
                }

                // タイプバッジ
                if wallpaper.type != .staticImage {
                    VStack {
                        HStack {
                            Spacer()
                            Text(wallpaper.type.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.ultraThinMaterial)
                                .cornerRadius(4)
                                .padding(6)
                        }
                        Spacer()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 名前
            Text(wallpaper.name)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - 右サイドバー
struct WallpaperSidebarView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    let wallpaper: WallpaperItem
    @Binding var selectedWallpaper: WallpaperItem?
    @State private var showingDeleteAlert = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 閉じるボタン
                HStack {
                    Spacer()
                    Button(action: { selectedWallpaper = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // プレビュー画像（一番上）
                if let thumbnail = wallpaper.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                        .padding(.horizontal)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 180)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                Text("No Preview")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        )
                        .padding(.horizontal)
                }

                // タイトル
                Text(wallpaper.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                // 画像情報
                VStack(alignment: .leading, spacing: 8) {
                    SidebarInfoRow(label: "Type", value: wallpaper.type.rawValue)

                    if let resolution = wallpaper.resolution {
                        SidebarInfoRow(label: "Resolution", value: resolution)
                    }

                    SidebarInfoRow(label: "Size", value: formatFileSize(wallpaper.fileSize))
                }
                .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                // アクションボタン
                VStack(spacing: 10) {
                    // 背景に設定ボタン（メイン）
                    Button(action: {
                        let success = wallpaperManager.setAsWallpaperForAllScreens(wallpaper)
                        if success {
                            alertMessage = "Wallpaper has been set successfully!"
                            showingSuccessAlert = true
                        } else {
                            alertMessage = "Failed to set wallpaper."
                            showingErrorAlert = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "desktopcomputer")
                            Text("Set as Wallpaper")
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
                                    let success = wallpaperManager.setAsWallpaper(wallpaper, for: NSScreen.screens[index])
                                    if success {
                                        alertMessage = "Wallpaper set for Display \(index + 1)!"
                                        showingSuccessAlert = true
                                    } else {
                                        alertMessage = "Failed to set wallpaper."
                                        showingErrorAlert = true
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "display.2")
                                Text("Set for Display...")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
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

                    // 削除ボタン
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                Spacer(minLength: 20)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Delete Wallpaper", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                wallpaperManager.removeWallpaper(wallpaper)
                selectedWallpaper = nil
            }
        } message: {
            Text("Are you sure you want to delete \"\(wallpaper.name)\"?")
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct SidebarInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.caption)
        }
    }
}
