import XCTest
@testable import Roulette

final class StatsCalculatorTests: XCTestCase {

    /// Fixed UTC calendar + reference "now" so day math is deterministic (no DST/locale drift).
    private var calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    private func now() -> Date {
        DateComponents(calendar: calendar, year: 2026, month: 6, day: 18, hour: 12).date!
    }

    private func record(daysAgo: Int, hour: Int = 9, kind: TaskKind = .need) -> CompletionRecord {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: now()))!
        let stamped = calendar.date(byAdding: .hour, value: hour, to: day)!
        return CompletionRecord(taskID: UUID(), titleSnapshot: "t-\(daysAgo)", kind: kind, completedAt: stamped)
    }

    func testTodayCountOnlyCountsToday() {
        let records = [record(daysAgo: 0), record(daysAgo: 0, hour: 14), record(daysAgo: 1)]
        let stats = StatsCalculator.compute(from: records, now: now(), calendar: calendar)
        XCTAssertEqual(stats.todayCount, 2)
        XCTAssertEqual(stats.totalCount, 3)
    }

    func testStreakConsecutiveDaysIncludingToday() {
        let records = [record(daysAgo: 0), record(daysAgo: 1), record(daysAgo: 2)]
        let stats = StatsCalculator.compute(from: records, now: now(), calendar: calendar)
        XCTAssertEqual(stats.streakDays, 3)
    }

    func testStreakBreaksOnGap() {
        let records = [record(daysAgo: 0), record(daysAgo: 1), record(daysAgo: 3)]
        let stats = StatsCalculator.compute(from: records, now: now(), calendar: calendar)
        XCTAssertEqual(stats.streakDays, 2)
    }

    func testStreakHangsFromYesterdayWhenTodayEmpty() {
        let records = [record(daysAgo: 1), record(daysAgo: 2)]
        let stats = StatsCalculator.compute(from: records, now: now(), calendar: calendar)
        XCTAssertEqual(stats.todayCount, 0)
        XCTAssertEqual(stats.streakDays, 2)
    }

    func testNoStreakWhenLastCompletionTwoDaysAgo() {
        let records = [record(daysAgo: 2), record(daysAgo: 3)]
        let stats = StatsCalculator.compute(from: records, now: now(), calendar: calendar)
        XCTAssertEqual(stats.streakDays, 0)
    }

    func testEmptyRecords() {
        let stats = StatsCalculator.compute(from: [], now: now(), calendar: calendar)
        XCTAssertEqual(stats, CompletionStats(todayCount: 0, streakDays: 0, totalCount: 0))
    }

    func testRecentIsNewestFirstAndCapped() {
        let records = (0..<20).map { record(daysAgo: $0) }
        let recent = StatsCalculator.recent(from: records, limit: 5)
        XCTAssertEqual(recent.count, 5)
        XCTAssertEqual(recent.first?.titleSnapshot, "t-0")
        XCTAssertEqual(recent.last?.titleSnapshot, "t-4")
    }
}
