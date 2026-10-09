import Foundation

/// A persisted snapshot of the kitty's emotional state.
///
/// `score` decays lazily toward the baseline (50) at read time — no timers,
/// survives process death, trivially testable with injected dates.
public struct MoodState: Codable, Equatable, Sendable {
    /// 0...100. Starts at 70: a fresh kitty gives you the benefit of the doubt.
    public var score: Double
    public var lastUpdated: Date
    /// Consecutive days with at least one completed task.
    public var streakDays: Int
    /// Start-of-day of the most recent day with a completion. nil = never.
    public var lastStreakDay: Date?

    public var tier: MoodTier { MoodTier(score: score) }

    public init(
        score: Double = 70,
        lastUpdated: Date = Date(),
        streakDays: Int = 0,
        lastStreakDay: Date? = nil
    ) {
        self.score = score
        self.lastUpdated = lastUpdated
        self.streakDays = streakDays
        self.lastStreakDay = lastStreakDay
    }
}
