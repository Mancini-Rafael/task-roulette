import Foundation
import SwiftData

/// A single shared SwiftData container, injected into both the `MenuBarExtra`
/// popover and the AppKit floating panel so they read/write the same store.
@MainActor
enum SharedStore {
    static let container: ModelContainer = {
        let schema = Schema([TaskItem.self, CompletionRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }()
}
