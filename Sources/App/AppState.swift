import SwiftUI

/// Shared UI state across the menu-bar popover and the floating panel.
/// Lightweight on purpose: routing + a one-shot "please spin" signal. The actual
/// spin runs in `SpinView` where the SwiftData context is available.
@MainActor
final class AppState: ObservableObject {
    enum Tab: String, CaseIterable, Identifiable {
        case spin, tasks, stats
        var id: String { rawValue }
        var title: String {
            switch self {
            case .spin: return "Spin"
            case .tasks: return "Tasks"
            case .stats: return "Stats"
            }
        }
        var symbol: String {
            switch self {
            case .spin: return "dice.fill"
            case .tasks: return "list.bullet"
            case .stats: return "chart.bar.fill"
            }
        }
    }

    @Published var selectedTab: Tab = .spin
    @Published var spinMode: SpinMode = .both

    /// Incremented when something (e.g. the global "spin now" hotkey) requests an
    /// immediate spin. `SpinView` observes the change and reacts once.
    @Published var spinRequestToken: Int = 0

    func requestSpin() {
        selectedTab = .spin
        spinRequestToken &+= 1
    }
}
