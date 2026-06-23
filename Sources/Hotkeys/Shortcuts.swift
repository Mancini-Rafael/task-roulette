import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Opens the menu-bar panel from anywhere. User-rebindable in Settings.
    /// Default: ⌃⌥Space.
    static let openRoulette = Self("openRoulette", default: .init(.space, modifiers: [.control, .option]))

    /// Opens the panel and immediately spins. Default: ⌃⌥R.
    static let spinNow = Self("spinNow", default: .init(.r, modifiers: [.control, .option]))
}
