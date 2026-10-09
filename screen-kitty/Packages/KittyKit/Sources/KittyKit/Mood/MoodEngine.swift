import Foundation

/// Pure, deterministic mood math. Every function takes `now` so tests can
/// inject time; nothing in here touches Date() directly.
public enum MoodEngine {
    public static let decayPerHour: Double = 1.5
    public static let baseline: Double = 50
    public static let minScore: Double = 0
    public static let maxScore: Double = 100

    // Event weights
    public static let taskCompletedPoints: Double = 12
    public static let onTimeBonus: Double = 4
    public static let taskOverduePenalty: Double = 10
    public static let nagIgnoredPenalty: Double = 3
    public static let allTasksDoneBonus: Double = 15
    public static let streakMilestoneBonus: Double = 15
    public static let appOpenedBonus: Double = 1

    /// Drift the score toward the baseline based on elapsed time since the
    /// state was last touched. Kitty forgives slowly: ~1.5 points per hour.
    public static func decay(_ state: MoodState, at now: Date) -> MoodState {
        var s = state
        let hours = max(0, now.timeIntervalSince(state.lastUpdated)) / 3600
        let drift = decayPerHour * hours

        if s.score > baseline {
            s.score = max(baseline, s.score - drift)
        } else if s.score < baseline {
            s.score = min(baseline, s.score + drift)
        }
        s.lastUpdated = now
        return s
    }

    /// Apply an event (decay runs first, then the nudge).
    public static func apply(_ event: MoodEvent, to state: MoodState, at now: Date) -> MoodState {
        var s = decay(state, at: now)
        switch event {
        case .taskCompleted(let onTime):
            s.score += taskCompletedPoints + (onTime ? onTimeBonus : 0)
        case .taskOverdue:
            s.score -= taskOverduePenalty
        case .nagIgnored:
            s.score -= nagIgnoredPenalty
        case .allTasksDoneToday:
            s.score += allTasksDoneBonus
        case .streakMilestone:
            s.score += streakMilestoneBonus
        case .appOpened:
            s.score += appOpenedBonus
        }
        s.score = min(maxScore, max(minScore, s.score))
        return s
    }

    /// The result of completing a task: mood update + streak bookkeeping.
    /// Returns the updated state and, if the new streak hit a multiple of 3,
    /// the streak value that should be announced as a milestone.
    public static func applyCompletion(
        onTime: Bool,
        to state: MoodState,
        at now: Date,
        calendar: Calendar = .current
    ) -> (state: MoodState, milestone: Int?) {
        var s = apply(.taskCompleted(onTime: onTime), to: state, at: now)

        let today = calendar.startOfDay(for: now)
        var milestone: Int? = nil

        if s.lastStreakDay == today {
            // Already counted today.
        } else if let last = s.lastStreakDay,
                  calendar.isDate(last, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today)!) {
            s.streakDays += 1
        } else {
            s.streakDays = 1
        }
        s.lastStreakDay = today

        if s.streakDays > 0 && s.streakDays % 3 == 0 {
            milestone = s.streakDays
            s = apply(.streakMilestone(s.streakDays), to: s, at: now)
        }
        return (s, milestone)
    }
}
