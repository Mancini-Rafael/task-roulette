import SwiftUI
import SwiftData

@main
struct RouletteApp: App {
    // The status item, floating panel, and hotkeys are all managed in AppKit by the
    // delegate. The menu-bar icon and the hotkey both drive the same NSPanel, so the
    // SwiftUI side only needs to declare the Settings window.
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Hotkey rebinding lives in the standard Settings window.
        Settings {
            SettingsView()
        }
    }
}
