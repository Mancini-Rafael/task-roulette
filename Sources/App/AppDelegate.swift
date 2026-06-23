import AppKit
import KeyboardShortcuts

/// Owns the menu-bar status item, the floating panel, and the global hotkeys. Lives
/// for the whole app lifetime (unlike SwiftUI scene views), so it's the right home
/// for all the AppKit-level wiring.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private lazy var panelController = PanelController(appState: appState)
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        registerHotkeys()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "dice.fill", accessibilityDescription: "Roulette")
            button.action = #selector(togglePanel)
            button.target = self
        }
        statusItem = item
    }

    private func registerHotkeys() {
        KeyboardShortcuts.onKeyUp(for: .openRoulette) { [weak self] in
            self?.panelController.toggle(relativeTo: self?.statusItem?.button)
        }

        KeyboardShortcuts.onKeyUp(for: .spinNow) { [weak self] in
            guard let self else { return }
            self.appState.requestSpin()
            self.panelController.show(relativeTo: self.statusItem?.button)
        }
    }

    @objc private func togglePanel() {
        panelController.toggle(relativeTo: statusItem?.button)
    }
}
