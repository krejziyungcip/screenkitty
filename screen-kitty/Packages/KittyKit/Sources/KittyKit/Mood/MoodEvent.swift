import Foundation

/// Things that can happen to the kitty. Each one nudges the mood score.
public enum MoodEvent: Equatable, Sendable {
    /// A task got done. `onTime` earns a small bonus.
    case taskCompleted(onTime: Bool)
    /// A task's due date passed without completion.
    case taskOverdue
    /// A nag fired and the user did nothing (detected on next foreground).
    case nagIgnored
    /// Every task scheduled for today is complete.
    case allTasksDoneToday
    /// Streak hit a multiple of 3.
    case streakMilestone(Int)
    /// User opened the app. Tiny positive tick.
    case appOpened
}
