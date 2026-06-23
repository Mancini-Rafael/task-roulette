import Foundation
import SwiftData

/// A single task in either bucket. Named `TaskItem` to avoid colliding with
/// Swift Concurrency's `Task`.
@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String

    /// Stored as raw values; SwiftData predicates work best on primitives.
    var kindRaw: String
    var priorityRaw: Int

    /// When true, completing the task logs a completion but leaves it in the pool
    /// (recurring chore). When false, completion archives it (one-shot).
    var repeats: Bool

    var tags: [String]

    /// One-shot tasks become archived on completion: gone from the wheel, kept
    /// so history/edits stay consistent. Recurring tasks never archive this way.
    var isArchived: Bool

    var createdAt: Date
    var lastCompletedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        kind: TaskKind,
        priority: Priority = .medium,
        repeats: Bool = false,
        tags: [String] = [],
        isArchived: Bool = false,
        createdAt: Date = .now,
        lastCompletedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.kindRaw = kind.rawValue
        self.priorityRaw = priority.rawValue
        self.repeats = repeats
        self.tags = tags
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.lastCompletedAt = lastCompletedAt
    }

    var kind: TaskKind {
        get { TaskKind(rawValue: kindRaw) ?? .need }
        set { kindRaw = newValue.rawValue }
    }

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }
}
