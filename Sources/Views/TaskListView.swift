import SwiftUI
import SwiftData

/// Manage the task pool: add, edit, archive, delete. Grouped by bucket.
struct TaskListView: View {
    @Environment(\.modelContext) private var context

    @Query(filter: #Predicate<TaskItem> { $0.isArchived == false },
           sort: \TaskItem.createdAt, order: .reverse)
    private var tasks: [TaskItem]

    @State private var editing: TaskItem?
    @State private var isAdding = false
    @State private var pendingDelete: TaskItem?

    var body: some View {
        VStack(spacing: 0) {
            header

            if tasks.isEmpty {
                ContentUnavailableView(
                    "No tasks yet",
                    systemImage: "plus.circle",
                    description: Text("Add things you need to do and things you want to do.")
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    section(for: .need)
                    section(for: .want)
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $isAdding) {
            TaskEditorView(task: nil)
        }
        .sheet(item: $editing) { task in
            TaskEditorView(task: task)
        }
        .confirmationDialog(
            "Delete this task?",
            isPresented: deleteDialogBinding,
            presenting: pendingDelete
        ) { task in
            Button("Delete “\(task.title)”", role: .destructive) {
                context.delete(task)
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("This permanently removes the task. Completion history is kept.")
        }
    }

    private var deleteDialogBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )
    }

    private var header: some View {
        HStack {
            Text("Tasks").font(.headline)
            Spacer()
            Button("Add", systemImage: "plus") { isAdding = true }
                .buttonStyle(.borderless)
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func section(for kind: TaskKind) -> some View {
        let items = tasks.filter { $0.kind == kind }
        if !items.isEmpty {
            Section(kind.label) {
                ForEach(items) { task in
                    TaskRow(
                        task: task,
                        onEdit: { editing = task },
                        onArchive: { task.isArchived = true },
                        onDelete: { pendingDelete = task }
                    )
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            pendingDelete = task
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            task.isArchived = true
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(.gray)
                    }
                }
            }
        }
    }
}

private struct TaskRow: View {
    @Bindable var task: TaskItem
    let onEdit: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: task.kind.symbol)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            // Tapping the title area edits the task.
            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title).lineLimit(1)
                    HStack(spacing: 6) {
                        Text(task.priority.label)
                        if task.repeats {
                            Label("Repeats", systemImage: "repeat").labelStyle(.iconOnly)
                        }
                        if !task.tags.isEmpty {
                            Text(task.tags.map { "#\($0)" }.joined(separator: " "))
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            PriorityDot(priority: task.priority)

            Button(action: onArchive) {
                Image(systemName: "archivebox")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Archive — hide from the wheel, keep in history")

            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
            .help("Delete permanently")
        }
        .padding(.vertical, 2)
    }
}

private struct PriorityDot: View {
    let priority: Priority
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .help("\(priority.label) priority")
    }
    private var color: Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}
