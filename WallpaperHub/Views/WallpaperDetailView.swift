import SwiftUI
import AVKit

struct WallpaperDetailView: View {
    // MARK: - Constants
    private enum Layout {
        static let maxPreviewHeight: CGFloat = 400
        static let contentSpacing: CGFloat = 20
        static let cardSpacing: CGFloat = 16
        static let cardCornerRadius: CGFloat = 12
        static let buttonSpacing: CGFloat = 12
        static let maxPropertiesDisplay = 5
        static let labelWidth: CGFloat = 100
    }

    private enum Messages {
        static let allDisplaysSuccess = "Wallpaper has been set for all displays successfully!"
        static let allDisplaysError = "Failed to set wallpaper. Please make sure the app has the necessary permissions."
        static func displaySuccess(_ index: Int) -> String {
            "Wallpaper has been set for Display \(index + 1) successfully!"
        }
        static func displayError(_ index: Int) -> String {
            "Failed to set wallpaper for Display \(index + 1)."
        }
        static func deleteConfirmation(_ name: String) -> String {
            "Are you sure you want to delete \"\(name)\"? This action cannot be undone."
        }
    }

    // MARK: - Properties
    @EnvironmentObject var wallpaperManager: WallpaperManager
    let wallpaper: WallpaperItem
    @State private var showingDeleteAlert = false
    @State private var selectedScreen: NSScreen?
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var alertMessage = ""

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: Layout.contentSpacing) {
                wallpaperPreview
                    .frame(maxHeight: Layout.maxPreviewHeight)

                VStack(alignment: .leading, spacing: Layout.cardSpacing) {
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

                    if isWallpaperEngineType {
                        wallpaperEngineDetailsSection
                    }

                    Divider()

                    actionButtonsSection
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(Layout.cardCornerRadius)
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
            Text(Messages.deleteConfirmation(wallpaper.name))
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

    // MARK: - Computed Properties
    private var isWallpaperEngineType: Bool {
        wallpaper.type == .wallpaperEngine && wallpaper.wallpaperEngineProject != nil
    }

    private var hasMultipleDisplays: Bool {
        NSScreen.screens.count > 1
    }

    // MARK: - View Sections
    @ViewBuilder
    private var wallpaperEngineDetailsSection: some View {
        if let project = wallpaper.wallpaperEngineProject {
            Divider()

            Text("Wallpaper Engine Details")
                .font(.headline)
                .padding(.top, 8)

            InfoRow(label: "Project Type", value: project.wallpaperType)

            if let workshopID = project.workshopID {
                InfoRow(label: "Workshop ID", value: workshopID)
            }

            if let description = project.project.description, !description.isEmpty {
                projectDescriptionView(description)
            }

            if !project.configurableProperties.isEmpty {
                projectPropertiesView(project.configurableProperties)
            }
        }
    }

    @ViewBuilder
    private var actionButtonsSection: some View {
        VStack(spacing: Layout.buttonSpacing) {
            setAllDisplaysButton

            if hasMultipleDisplays {
                specificDisplayMenu
            }

            showInFinderButton
            deleteButton
        }
    }

    @ViewBuilder
    private var wallpaperPreview: some View {
        switch wallpaper.type {
        case .staticImage, .animatedImage:
            imagePreview
        case .video:
            videoPreview
        case .wallpaperEngine:
            wallpaperEnginePreview
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let image = wallpaper.thumbnail {
            thumbnailImage(image)
        }
    }

    @ViewBuilder
    private var videoPreview: some View {
        VideoPlayer(player: AVPlayer(url: wallpaper.fileURL))
            .aspectRatio(16/9, contentMode: .fit)
            .cornerRadius(Layout.cardCornerRadius)
            .shadow(radius: 10)
    }

    @ViewBuilder
    private var wallpaperEnginePreview: some View {
        if let image = wallpaper.thumbnail {
            thumbnailImage(image)
                .overlay(wallpaperEngineBadge)
        } else {
            wallpaperEnginePlaceholder
        }
    }

    // MARK: - Helper Views
    @ViewBuilder
    private func thumbnailImage(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .cornerRadius(Layout.cardCornerRadius)
            .shadow(radius: 10)
    }

    @ViewBuilder
    private var wallpaperEngineBadge: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "gearshape.fill")
                Text("Wallpaper Engine")
            }
            .font(.caption)
            .padding(8)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
            .padding()
        }
    }

    @ViewBuilder
    private var wallpaperEnginePlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.3)
            VStack(spacing: 12) {
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("Wallpaper Engine")
                    .font(.headline)
                    .foregroundColor(.secondary)
                if let project = wallpaper.wallpaperEngineProject {
                    Text(project.wallpaperType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .cornerRadius(Layout.cardCornerRadius)
        .shadow(radius: 10)
    }

    @ViewBuilder
    private func projectDescriptionView(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Description")
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text(description)
                .textSelection(.enabled)
                .font(.caption)
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func projectPropertiesView(_ properties: [String: WallpaperEngineProject.Property]) -> some View {
        Text("Properties")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
            .padding(.top, 8)

        ForEach(Array(properties.keys.sorted().prefix(Layout.maxPropertiesDisplay)), id: \.self) { key in
            if let property = properties[key] {
                propertyRow(key: key, property: property)
            }
        }
    }

    @ViewBuilder
    private func propertyRow(key: String, property: WallpaperEngineProject.Property) -> some View {
        HStack {
            Text(property.text ?? key)
                .font(.caption)
            Spacer()
            Text(property.type ?? "unknown")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Action Buttons
    @ViewBuilder
    private var setAllDisplaysButton: some View {
        Button(action: handleSetAllDisplays) {
            HStack {
                Image(systemName: "display.2")
                Text("Set for All Displays")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressableButtonStyle(isPrimary: true))
        .controlSize(.large)
    }

    @ViewBuilder
    private var specificDisplayMenu: some View {
        Menu {
            ForEach(NSScreen.screens.indices, id: \.self) { index in
                Button("Display \(index + 1)") {
                    handleSetSpecificDisplay(at: index)
                }
            }
        } label: {
            HStack {
                Image(systemName: "display")
                Text("Set for Specific Display")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressableButtonStyle(isPrimary: false))
        .controlSize(.large)
    }

    @ViewBuilder
    private var showInFinderButton: some View {
        Button(action: showInFinder) {
            HStack {
                Image(systemName: "folder")
                Text("Show in Finder")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressableButtonStyle(isPrimary: false))
        .controlSize(.large)
    }

    @ViewBuilder
    private var deleteButton: some View {
        Button(role: .destructive, action: { showingDeleteAlert = true }) {
            HStack {
                Image(systemName: "trash")
                Text("Delete Wallpaper")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressableButtonStyle(isPrimary: false, isDestructive: true))
        .controlSize(.large)
    }

    // MARK: - Action Handlers
    private func handleSetAllDisplays() {
        let success = wallpaperManager.setAsWallpaperForAllScreens(wallpaper)
        showAlert(success: success,
                  successMessage: Messages.allDisplaysSuccess,
                  errorMessage: Messages.allDisplaysError)
    }

    private func handleSetSpecificDisplay(at index: Int) {
        let screen = NSScreen.screens[index]
        let success = wallpaperManager.setAsWallpaper(wallpaper, for: screen)
        showAlert(success: success,
                  successMessage: Messages.displaySuccess(index),
                  errorMessage: Messages.displayError(index))
    }

    private func showInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([wallpaper.fileURL])
    }

    private func showAlert(success: Bool, successMessage: String, errorMessage: String) {
        alertMessage = success ? successMessage : errorMessage
        if success {
            showingSuccessAlert = true
        } else {
            showingErrorAlert = true
        }
    }

    // MARK: - Formatting Helpers

    private func formatFileSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views
struct InfoRow: View {
    private enum Constants {
        static let labelWidth: CGFloat = 100
    }

    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: Constants.labelWidth, alignment: .leading)

            Text(value)
                .textSelection(.enabled)

            Spacer()
        }
    }
}

// MARK: - Custom Button Style
struct PressableButtonStyle: ButtonStyle {
    let isPrimary: Bool
    let isDestructive: Bool

    init(isPrimary: Bool = false, isDestructive: Bool = false) {
        self.isPrimary = isPrimary
        self.isDestructive = isDestructive
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isDestructive {
            return isPressed ? Color.red.opacity(0.2) : Color.red.opacity(0.1)
        } else if isPrimary {
            return isPressed ? Color.accentColor.opacity(0.8) : Color.accentColor
        } else {
            return isPressed ? Color.gray.opacity(0.3) : Color.gray.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        if isDestructive {
            return .red
        } else if isPrimary {
            return .white
        } else {
            return .primary
        }
    }

    private var borderColor: Color {
        if isDestructive {
            return Color.red.opacity(0.3)
        } else if isPrimary {
            return Color.accentColor.opacity(0.5)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}
