import SwiftUI
import SwiftData

/// Today's count, current streak, and recent completions — the dopamine surface.
struct StatsView: View {
    @Query(sort: \CompletionRecord.completedAt, order: .reverse)
    private var records: [CompletionRecord]

    private var stats: CompletionStats {
        StatsCalculator.compute(from: records, now: .now)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                StatTile(value: "\(stats.todayCount)", label: "Today", symbol: "calendar")
                StatTile(value: "\(stats.streakDays)", label: "Day streak", symbol: "flame.fill")
                StatTile(value: "\(stats.totalCount)", label: "All time", symbol: "checkmark.seal.fill")
            }

            Text("Recent")
                .font(.headline)

            if records.isEmpty {
                ContentUnavailableView(
                    "No completions yet",
                    systemImage: "checkmark.circle",
                    description: Text("Finish a spun task to start your streak.")
                )
                .frame(maxHeight: .infinity)
            } else {
                List(StatsCalculator.recent(from: records, limit: 15)) { record in
                    HStack {
                        Image(systemName: record.kind.symbol)
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Text(record.titleSnapshot).lineLimit(1)
                        Spacer()
                        Text(record.completedAt, format: .relative(presentation: .named))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .listStyle(.inset)
            }
        }
        .padding()
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let symbol: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: symbol).foregroundStyle(.tint)
            Text(value).font(.title2.weight(.bold))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
}
