import AppKit
import SwiftUI

/// Owns a floating panel that hosts `RootView`. This is the single interactive
/// surface for both the menu-bar icon and the global hotkey.
///
/// Why not `MenuBarExtra(.window)`? Its popover is a transient `NSPopover` that
/// auto-dismisses whenever another window becomes key — which a `Picker` menu or a
/// `.sheet` both do, so the panel vanished mid-interaction. A panel we own doesn't.
@MainActor
final class PanelController {
    private var panel: NSPanel?
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    /// `anchor` is the menu-bar status button, so the panel drops directly beneath it.
    func toggle(relativeTo anchor: NSStatusBarButton? = nil) {
        if let panel, panel.isVisible {
            hide()
        } else {
            show(relativeTo: anchor)
        }
    }

    func show(relativeTo anchor: NSStatusBarButton? = nil) {
        let panel = existingOrNewPanel()
        position(panel, below: anchor)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func existingOrNewPanel() -> NSPanel {
        if let panel { return panel }

        let hosting = NSHostingController(
            rootView: RootView()
                .modelContainer(SharedStore.container)
                .environmentObject(appState)
        )

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 460),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.isMovableByWindowBackground = true
        panel.isFloatingPanel = true
        panel.level = .floating
        // Popover-like: close when the user switches to another app, but NOT when a
        // sheet or picker (same-app) takes focus — that was the original bug.
        panel.hidesOnDeactivate = true
        panel.contentViewController = hosting
        panel.isReleasedWhenClosed = false

        self.panel = panel
        return panel
    }

    /// Positions the panel just under the menu bar: beneath the status item if we
    /// have one, else horizontally centered on the screen holding the mouse.
    private func position(_ panel: NSPanel, below anchor: NSStatusBarButton?) {
        let size = panel.frame.size

        if let anchor, let window = anchor.window {
            let buttonRect = anchor.convert(anchor.bounds, to: nil)
            let onScreen = window.convertToScreen(buttonRect)
            let x = onScreen.midX - size.width / 2
            let y = onScreen.minY - size.height - 4
            panel.setFrameOrigin(clamp(NSPoint(x: x, y: y), size: size, to: window.screen))
            return
        }

        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }
        let x = visible.midX - size.width / 2
        let y = visible.maxY - size.height - 8
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    /// Keeps the panel fully on-screen when the status item sits near a screen edge.
    private func clamp(_ origin: NSPoint, size: NSSize, to screen: NSScreen?) -> NSPoint {
        guard let visible = screen?.visibleFrame else { return origin }
        let x = min(max(origin.x, visible.minX + 8), visible.maxX - size.width - 8)
        let y = min(max(origin.y, visible.minY + 8), visible.maxY - size.height - 8)
        return NSPoint(x: x, y: y)
    }
}
