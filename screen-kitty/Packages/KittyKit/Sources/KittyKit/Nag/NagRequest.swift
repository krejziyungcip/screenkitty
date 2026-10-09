import Foundation

/// A pure description of one future notification. Contains no
/// UNUserNotificationCenter types, so planning stays Linux-testable.
public struct NagRequest: Identifiable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case dueReminder
        case overdueEscalation
        case dailyAnchor
        case streakAtRisk
    }

    /// Deterministic ID. Re-planning replaces requests with the same ID.
    public var id: String
    public var kind: Kind
    /// Lower = more important when trimming to the daily cap.
    public var priority: Int
    public var title: String
    public var body: String
    public var fireDate: Date

    public init(
        id: String,
        kind: Kind,
        priority: Int,
        title: String,
        body: String,
        fireDate: Date
    ) {
        self.id = id
        self.kind = kind
        self.priority = priority
        self.title = title
        self.body = body
        self.fireDate = fireDate
    }
}
