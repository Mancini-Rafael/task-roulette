import SwiftUI

/// The shared content for both the menu-bar popover and the floating panel.
struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $appState.selectedTab) {
                SpinView()
                    .tabItem { Label(AppState.Tab.spin.title, systemImage: AppState.Tab.spin.symbol) }
                    .tag(AppState.Tab.spin)

                TaskListView()
                    .tabItem { Label(AppState.Tab.tasks.title, systemImage: AppState.Tab.tasks.symbol) }
                    .tag(AppState.Tab.tasks)

                StatsView()
                    .tabItem { Label(AppState.Tab.stats.title, systemImage: AppState.Tab.stats.symbol) }
                    .tag(AppState.Tab.stats)
            }
            .padding(.top, 8)

            Divider()
            FooterBar()
        }
        .frame(width: 360, height: 460)
    }
}

private struct FooterBar: View {
    var body: some View {
        HStack(spacing: 12) {
            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .help("Settings & hotkeys")

            Spacer()

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .help("Quit Roulette")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .font(.body)
    }
}
