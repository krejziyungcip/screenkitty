import Foundation

/// A single to-do item the kitty keeps tabs on.
public struct KittyTask: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    /// nil = no deadline (kitty still nudges gently).
    public var due: Date?
    public var completedAt: Date?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        due: Date? = nil,
        completedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.due = due
        self.completedAt = completedAt
        self.createdAt = createdAt
    }

    public var isCompleted: Bool { completedAt != nil }

    public func isOverdue(at now: Date = Date()) -> Bool {
        guard let due, !isCompleted else { return false }
        return now > due
    }

    /// Was this completed before its deadline (or has no deadline)?
    public func completedOnTime(at now: Date = Date()) -> Bool {
        guard let due else { return true }
        return now <= due
    }
}
