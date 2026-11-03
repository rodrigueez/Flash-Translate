import SwiftUI

@main
struct FlashTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppBootstrap.sharedState

    init() {
        NSApp?.setActivationPolicy(.accessory)
        appDelegate.appState = AppBootstrap.sharedState
    }

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appState)
                .frame(width: 520, height: 500)
        }
        .commands {
            CommandGroup(replacing: .appInfo) { }
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
        .commands {
            CommandGroup(replacing: .help) { }
        }
    }
}
