import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(isTargeted ? .accentColor : .secondary)

            VStack(spacing: 8) {
                Text("Drop images or videos here")
                    .font(.title2)
                    .fontWeight(.medium)

                Text("or click the + button to browse")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                Text("Supported formats:")
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    FormatBadge(text: "PNG")
                    FormatBadge(text: "JPG")
                    FormatBadge(text: "GIF")
                    FormatBadge(text: "MP4")
                    FormatBadge(text: "MOV")
                }
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [10, 5])
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
                )
        )
        .padding()
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var handled = false

        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
                guard let urlData = data as? Data,
                      let url = URL(dataRepresentation: urlData, relativeTo: nil) else {
                    return
                }

                // ファイルタイプを確認
                let validExtensions = ["png", "jpg", "jpeg", "gif", "mp4", "mov", "avi", "mkv", "m4v", "heic", "webp"]
                let fileExtension = url.pathExtension.lowercased()

                if validExtensions.contains(fileExtension) {
                    DispatchQueue.main.async {
                        wallpaperManager.addWallpaper(from: url)
                    }
                    handled = true
                }
            }
        }

        return handled
    }
}

struct FormatBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.2))
            .foregroundColor(.accentColor)
            .cornerRadius(4)
    }
}
