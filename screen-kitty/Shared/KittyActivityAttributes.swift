import ActivityKit
import KittyKit

/// Defines the Dynamic Island / Lock Screen Live Activity.
/// All mutable content lives in ContentState; the attributes payload is
/// empty because everything (task, mood, counts) changes over time.
///
/// Local updates only — push-to-start/push-update requires a paid
/// developer account, so this never gets a push token.
public struct KittyActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var tier: MoodTier
        public var openCount: Int
        public var overdueCount: Int
        public var streakDays: Int
        public var nextTaskTitle: String?
        /// Countdown target rendered with Text(timerInterval:) so the UI
        /// self-advances without any updates.
        public var nextDue: Date?

        public init(
            tier: MoodTier,
            openCount: Int,
            overdueCount: Int,
            streakDays: Int,
            nextTaskTitle: String?,
            nextDue: Date?
        ) {
            self.tier = tier
            self.openCount = openCount
            self.overdueCount = overdueCount
            self.streakDays = streakDays
            self.nextTaskTitle = nextTaskTitle
            self.nextDue = nextDue
        }
    }

    public init() {}
}
