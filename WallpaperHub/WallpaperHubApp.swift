import SwiftUI

@main
struct WallpaperHubApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var wallpaperManager = WallpaperManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(wallpaperManager)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            disableNewWindowCommand()
        }
    }

    private func disableNewWindowCommand() -> some Commands {
        CommandGroup(replacing: .newItem) {}
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        logApplicationLaunch()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func logApplicationLaunch() {
        print("Wallpaper Hub started")
    }
}
