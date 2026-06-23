import Foundation

/// Aggregated completion stats for the Stats tab. Pure value-in/value-out so it
/// unit-tests against hand-built dates with no store.
struct CompletionStats: Equatable, Sendable {
    var todayCount: Int
    var streakDays: Int
    var totalCount: Int
}

enum StatsCalculator {
    /// Computes today's completion count, the current daily streak, and the total.
    ///
    /// - `now` and `calendar` are injected for deterministic tests.
    /// - Streak = number of consecutive calendar days, ending today, that each have at
    ///   least one completion. If there are completions yesterday but none today, the
    ///   streak still counts yesterday's run (today simply isn't logged yet).
    static func compute(
        from records: [CompletionRecord],
        now: Date,
        calendar: Calendar = .current
    ) -> CompletionStats {
        let total = records.count
        let today = calendar.startOfDay(for: now)

        let todayCount = records.filter {
            calendar.isDate($0.completedAt, inSameDayAs: now)
        }.count

        // Set of distinct day-starts that have at least one completion.
        let completedDays = Set(records.map { calendar.startOfDay(for: $0.completedAt) })

        // Walk backward from today (or yesterday if today is empty) counting consecutive days.
        var streak = 0
        var cursor = today
        if !completedDays.contains(today) {
            // Allow the streak to "hang" from yesterday before today's first completion.
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  completedDays.contains(yesterday) else {
                return CompletionStats(todayCount: todayCount, streakDays: 0, totalCount: total)
            }
            cursor = yesterday
        }

        while completedDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return CompletionStats(todayCount: todayCount, streakDays: streak, totalCount: total)
    }

    /// Most recent completions, newest first, capped at `limit`.
    static func recent(from records: [CompletionRecord], limit: Int = 10) -> [CompletionRecord] {
        records.sorted { $0.completedAt > $1.completedAt }.prefix(limit).map { $0 }
    }
}
