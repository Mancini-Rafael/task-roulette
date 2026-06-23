import SwiftUI
import SwiftData

/// Add or edit a task. When `task` is nil we're creating; otherwise editing in place.
struct TaskEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let task: TaskItem?

    @State private var title = ""
    @State private var notes = ""
    @State private var kind: TaskKind = .need
    @State private var priority: Priority = .medium
    @State private var repeats = false
    @State private var tagsText = ""

    private var isEditing: Bool { task != nil }

    var body: some View {
        VStack(spacing: 0) {
            Text(isEditing ? "Edit Task" : "New Task")
                .font(.headline)
                .padding()

            Form {
                TextField("Title", text: $title)

                Picker("Bucket", selection: $kind) {
                    ForEach(TaskKind.allCases) { Text($0.label).tag($0) }
                }

                Picker("Priority", selection: $priority) {
                    ForEach(Priority.allCases) { Text($0.label).tag($0) }
                }

                Toggle("Repeats (stays after Done)", isOn: $repeats)

                TextField("Tags (comma-separated)", text: $tagsText)

                VStack(alignment: .leading) {
                    Text("Notes").font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $notes)
                        .frame(height: 60)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.quaternary))
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                Spacer()
                Button(isEditing ? "Save" : "Add") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(width: 340, height: 440)
        .onAppear(perform: load)
    }

    private func load() {
        guard let task else { return }
        title = task.title
        notes = task.notes
        kind = task.kind
        priority = task.priority
        repeats = task.repeats
        tagsText = task.tags.joined(separator: ", ")
    }

    private func save() {
        let cleanTitle = title.trimmingCharacters(in: .whitespaces)
        guard !cleanTitle.isEmpty else { return }
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if let task {
            task.title = cleanTitle
            task.notes = notes
            task.kind = kind
            task.priority = priority
            task.repeats = repeats
            task.tags = tags
        } else {
            let new = TaskItem(
                title: cleanTitle,
                notes: notes,
                kind: kind,
                priority: priority,
                repeats: repeats,
                tags: tags
            )
            context.insert(new)
        }
        try? context.save()
        dismiss()
    }
}
