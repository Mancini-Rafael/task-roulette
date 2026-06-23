import SwiftUI
import KeyboardShortcuts

/// Rebind the global hotkeys and support the project. Shown in the standard
/// macOS Settings window.
struct SettingsView: View {
    /// TODO: replace with your real GitHub handle before release.
    private let sponsorURL = URL(string: "https://github.com/sponsors/your-handle")!

    var body: some View {
        Form {
            Section("Global Hotkeys") {
                KeyboardShortcuts.Recorder("Open Roulette", name: .openRoulette)
                KeyboardShortcuts.Recorder("Spin now", name: .spinNow)
            }

            Section {
                Text("Hotkeys work system-wide. “Spin now” opens the panel and immediately picks a task.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Support") {
                Link(destination: sponsorURL) {
                    Label("Buy me a coffee ☕️", systemImage: "heart.fill")
                }
                .help("Sponsor development on GitHub")
            }

            Section {
                HStack {
                    Text("Roulette")
                    Spacer()
                    Text(appVersion).foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 320)
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "v\(short) (\(build))"
    }
}
