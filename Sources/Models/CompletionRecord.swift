import Foundation
import SwiftData

/// A denormalized snapshot of a completed task. Stored separately from `TaskItem`
/// so completion history survives editing, archiving, or deleting the source task.
@Model
final class CompletionRecord {
    @Attribute(.unique) var id: UUID
    var taskID: UUID
    var titleSnapshot: String
    var kindRaw: String
    var completedAt: Date

    init(
        id: UUID = UUID(),
        taskID: UUID,
        titleSnapshot: String,
        kind: TaskKind,
        completedAt: Date = .now
    ) {
        self.id = id
        self.taskID = taskID
        self.titleSnapshot = titleSnapshot
        self.kindRaw = kind.rawValue
        self.completedAt = completedAt
    }

    var kind: TaskKind { TaskKind(rawValue: kindRaw) ?? .need }
}
