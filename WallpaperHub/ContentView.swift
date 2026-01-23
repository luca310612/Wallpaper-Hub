import SwiftUI

struct ContentView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @State private var selectedWallpaper: WallpaperItem?
    @State private var showingFilePicker = false
    @State private var searchText = ""

    var filteredWallpapers: [WallpaperItem] {
        if searchText.isEmpty {
            return wallpaperManager.wallpapers
        } else {
            return wallpaperManager.wallpapers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationSplitView {
            // サイドバー
            VStack(spacing: 0) {
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
                .padding()

                // 壁紙リスト
                List(filteredWallpapers, selection: $selectedWallpaper) { wallpaper in
                    WallpaperListItem(wallpaper: wallpaper)
                }
                .listStyle(.sidebar)

                Divider()

                // 追加ボタン
                HStack {
                    Button(action: { showingFilePicker = true }) {
                        Label("Add Wallpaper", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)

                    Spacer()

                    Button(action: { wallpaperManager.refreshWallpapers() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                }
                .padding()
            }
        } detail: {
            // 詳細ビュー
            if let wallpaper = selectedWallpaper {
                WallpaperDetailView(wallpaper: wallpaper)
            } else if wallpaperManager.wallpapers.isEmpty {
                // 空の状態でドロップゾーンを表示
                DropZoneView()
            } else {
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Select a wallpaper")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.image, .movie],
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

struct WallpaperListItem: View {
    let wallpaper: WallpaperItem

    var body: some View {
        HStack(spacing: 12) {
            // サムネイル
            if let thumbnail = wallpaper.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 60, height: 40)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(wallpaper.name)
                    .font(.headline)
                Text(wallpaper.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
