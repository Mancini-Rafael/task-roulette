import Foundation

/// A pool entry for the roulette: an identity plus its selection weight.
struct WeightedCandidate: Equatable, Sendable {
    let id: UUID
    let weight: Int
}

/// Pure weighted-random selection. Decoupled from SwiftData so it unit-tests with a
/// seeded RNG and no ModelContainer. This is the core of the product — keep it simple
/// and deterministic under test.
enum TaskPicker {
    /// Picks one candidate with probability proportional to its weight.
    /// Non-positive weights are clamped to 0 (never selected). Returns `nil` when the
    /// pool is empty or every weight is <= 0.
    static func pick<G: RandomNumberGenerator>(
        from candidates: [WeightedCandidate],
        using rng: inout G
    ) -> UUID? {
        let total = candidates.reduce(0) { $0 + max(0, $1.weight) }
        guard total > 0 else { return nil }

        var roll = Int.random(in: 0..<total, using: &rng)
        for candidate in candidates {
            let weight = max(0, candidate.weight)
            if roll < weight { return candidate.id }
            roll -= weight
        }
        // Unreachable when total > 0, but stay total: return the last eligible id.
        return candidates.last(where: { $0.weight > 0 })?.id
    }

    /// Convenience using the system RNG.
    static func pick(from candidates: [WeightedCandidate]) -> UUID? {
        var rng = SystemRandomNumberGenerator()
        return pick(from: candidates, using: &rng)
    }
}
