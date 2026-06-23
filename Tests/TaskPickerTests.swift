import XCTest
@testable import Roulette

final class TaskPickerTests: XCTestCase {

    func testEmptyPoolReturnsNil() {
        var rng = SeededRNG(seed: 1)
        XCTAssertNil(TaskPicker.pick(from: [], using: &rng))
    }

    func testAllZeroWeightReturnsNil() {
        var rng = SeededRNG(seed: 1)
        let candidates = [
            WeightedCandidate(id: UUID(), weight: 0),
            WeightedCandidate(id: UUID(), weight: 0),
        ]
        XCTAssertNil(TaskPicker.pick(from: candidates, using: &rng))
    }

    func testSingleCandidateAlwaysWins() {
        let id = UUID()
        var rng = SeededRNG(seed: 42)
        for _ in 0..<100 {
            XCTAssertEqual(TaskPicker.pick(from: [WeightedCandidate(id: id, weight: 3)], using: &rng), id)
        }
    }

    func testZeroWeightCandidateNeverPicked() {
        let never = UUID()
        let always = UUID()
        let candidates = [
            WeightedCandidate(id: never, weight: 0),
            WeightedCandidate(id: always, weight: 5),
        ]
        var rng = SeededRNG(seed: 7)
        for _ in 0..<1_000 {
            XCTAssertEqual(TaskPicker.pick(from: candidates, using: &rng), always)
        }
    }

    func testWeightingIsRoughlyProportional() {
        let low = UUID()   // weight 1
        let high = UUID()  // weight 6
        let candidates = [
            WeightedCandidate(id: low, weight: 1),
            WeightedCandidate(id: high, weight: 6),
        ]
        var rng = SeededRNG(seed: 123)
        var counts: [UUID: Int] = [low: 0, high: 0]
        let draws = 14_000
        for _ in 0..<draws {
            if let pick = TaskPicker.pick(from: candidates, using: &rng) {
                counts[pick, default: 0] += 1
            }
        }
        // Expected ratio is 6:1. Assert high is clearly favored and low isn't starved.
        XCTAssertGreaterThan(counts[high]!, counts[low]! * 4)
        XCTAssertLessThan(counts[high]!, counts[low]! * 9)
        XCTAssertGreaterThan(counts[low]!, 0)
    }

    func testEveryNonZeroCandidateReachableOverManyDraws() {
        let ids = (0..<4).map { _ in UUID() }
        let candidates = ids.map { WeightedCandidate(id: $0, weight: 2) }
        var rng = SeededRNG(seed: 999)
        var seen = Set<UUID>()
        for _ in 0..<2_000 {
            if let pick = TaskPicker.pick(from: candidates, using: &rng) { seen.insert(pick) }
        }
        XCTAssertEqual(seen, Set(ids))
    }
}
