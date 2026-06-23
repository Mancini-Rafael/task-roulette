import Foundation

/// Which bucket a task belongs to.
enum TaskKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case need
    case want

    var id: String { rawValue }

    var label: String {
        switch self {
        case .need: return "Need to do"
        case .want: return "Want to do"
        }
    }

    var symbol: String {
        switch self {
        case .need: return "checklist"
        case .want: return "sparkles"
        }
    }
}

/// User-set priority. Drives the weight used by the roulette.
enum Priority: Int, Codable, CaseIterable, Identifiable, Sendable {
    case low = 1
    case medium = 2
    case high = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    /// Relative likelihood of being picked. Higher priority => proportionally more weight.
    /// Kept as a single source of truth so tuning the curve is a one-line change.
    var weight: Int {
        switch self {
        case .low: return 1
        case .medium: return 3
        case .high: return 6
        }
    }
}

/// What the user wants the wheel to consider on this spin. Guards against the
/// "wheel rationalises procrastination" failure mode by making intent explicit.
enum SpinMode: String, CaseIterable, Identifiable, Sendable {
    case both
    case need
    case want

    var id: String { rawValue }

    var label: String {
        switch self {
        case .both: return "Both"
        case .need: return "Need"
        case .want: return "Want"
        }
    }

    /// Returns true if a task of the given kind is eligible under this mode.
    func includes(_ kind: TaskKind) -> Bool {
        switch self {
        case .both: return true
        case .need: return kind == .need
        case .want: return kind == .want
        }
    }
}
