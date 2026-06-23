import SwiftUI
import SwiftData

/// The roulette itself: pick a mode, spin the reel, get one task, act on it.
struct SpinView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var context

    /// Only non-archived tasks are ever eligible; mode filtering happens in code.
    @Query(filter: #Predicate<TaskItem> { $0.isArchived == false },
           sort: \TaskItem.createdAt)
    private var activeTasks: [TaskItem]

    @State private var isSpinning = false
    @State private var result: TaskItem?

    // Reel state, rebuilt per spin.
    @State private var reelTitles: [String] = []
    @State private var reelWinnerIndex = 0
    @State private var reelSpinID = 0
    @State private var pendingWinner: TaskItem?

    var body: some View {
        VStack(spacing: 16) {
            Picker("", selection: $appState.spinMode) {
                ForEach(SpinMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal)

            stage
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            controls
        }
        .padding()
        .onChange(of: appState.spinRequestToken) { _, _ in spin() }
        .onChange(of: appState.spinMode) { _, _ in reset() }
    }

    // MARK: - Stage (center)

    @ViewBuilder
    private var stage: some View {
        if isSpinning || result != nil {
            VStack(spacing: 12) {
                SpinReelView(
                    titles: reelTitles,
                    winnerIndex: reelWinnerIndex,
                    spinID: reelSpinID,
                    settled: result != nil,
                    onSettled: handleSettled
                )
                .frame(height: 96)
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 14))

                if let result {
                    ResultDetails(task: result)
                        .transition(.opacity)
                }
            }
        } else if eligibleTasks.isEmpty {
            EmptyStage(mode: appState.spinMode)
        } else {
            IdleStage(count: eligibleTasks.count, mode: appState.spinMode)
        }
    }

    @ViewBuilder
    private var controls: some View {
        if let result, !isSpinning {
            HStack(spacing: 10) {
                Button("Re-spin", systemImage: "arrow.triangle.2.circlepath") { spin() }
                Button("Start", systemImage: "play.fill") { reset() }
                Button("Done", systemImage: "checkmark") { complete(result) }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            Button(action: spin) {
                Label(isSpinning ? "Spinning…" : "Spin", systemImage: "dice.fill")
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSpinning || eligibleTasks.isEmpty)
            .keyboardShortcut(.defaultAction)
        }
    }

    // MARK: - Logic

    private var eligibleTasks: [TaskItem] {
        activeTasks.filter { appState.spinMode.includes($0.kind) }
    }

    private func reset() {
        withAnimation {
            isSpinning = false
            result = nil
            pendingWinner = nil
            reelTitles = []
        }
    }

    private func spin() {
        let pool = eligibleTasks
        guard !pool.isEmpty else { reset(); return }

        let candidates = pool.map { WeightedCandidate(id: $0.id, weight: $0.priority.weight) }
        guard let winnerID = TaskPicker.pick(from: candidates),
              let winner = pool.first(where: { $0.id == winnerID }) else { return }

        // Build the reel strip: random fillers with the winner planted near the end so
        // the reel travels a long, fast distance before decelerating onto it.
        let winnerIndex = 22
        let count = winnerIndex + 4
        var titles = (0..<count).map { _ in pool.randomElement()?.title ?? winner.title }
        titles[winnerIndex] = winner.title

        pendingWinner = winner
        reelTitles = titles
        reelWinnerIndex = winnerIndex
        result = nil
        isSpinning = true
        reelSpinID &+= 1
    }

    private func handleSettled() {
        withAnimation(.easeOut(duration: 0.25)) {
            isSpinning = false
            result = pendingWinner
        }
    }

    /// Logs a completion, then archives one-shot tasks or leaves recurring ones in the pool.
    private func complete(_ task: TaskItem) {
        let record = CompletionRecord(
            taskID: task.id,
            titleSnapshot: task.title,
            kind: task.kind
        )
        context.insert(record)
        task.lastCompletedAt = .now
        if !task.repeats {
            task.isArchived = true
        }
        try? context.save()
        reset()
    }
}

// MARK: - Subviews

private struct ResultDetails: View {
    let task: TaskItem

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Tag(text: task.kind.label)
                Tag(text: task.priority.label)
                if task.repeats { Tag(text: "Repeats") }
            }
            if !task.notes.isEmpty {
                Text(task.notes)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
    }
}

private struct IdleStage: View {
    let count: Int
    let mode: SpinMode
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "dice")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text("\(count) task\(count == 1 ? "" : "s") in play")
                .font(.headline)
            Text("Mode: \(mode.label) — hit Spin to get one.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

private struct EmptyStage: View {
    let mode: SpinMode
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text("Nothing to spin")
                .font(.headline)
            Text(mode == .both
                 ? "Add a task in the Tasks tab."
                 : "No \(mode.label.lowercased()) tasks. Try another mode or add some.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
}

private struct Tag: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.quaternary, in: Capsule())
    }
}
