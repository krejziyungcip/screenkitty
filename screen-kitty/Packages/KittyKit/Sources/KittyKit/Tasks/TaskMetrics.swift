import Foundation

/// Computed view over the task list. Pure so both the app and the
/// Linux test suite can use it.
public struct TaskMetrics: Equatable, Sendable {
    public let openCount: Int
    public let overdueCount: Int
    public let completedToday: Int
    /// Earliest due date among open, not-yet-overdue tasks.
    public let nextDue: Date?
    /// The open task the kitty nags about first (overdue first, then by due).
    public let focusTask: KittyTask?

    public init(tasks: [KittyTask], at now: Date = Date(), calendar: Calendar = .current) {
        let open = tasks.filter { !$0.isCompleted }
        let overdue = open.filter { $0.isOverdue(at: now) }
        let upcoming = open.filter { task in
            guard let due = task.due else { return false }
            return due > now
        }
        let completed = tasks.filter { $0.isCompleted }

        self.openCount = open.count
        self.overdueCount = overdue.count
        self.completedToday = completed.filter { task in
            guard let at = task.completedAt else { return false }
            return calendar.isDate(at, inSameDayAs: now)
        }.count
        self.nextDue = upcoming.map { $0.due! }.min()
        self.focusTask = overdue.sorted { ($0.due ?? .distantPast) < ($1.due ?? .distantPast) }.first
            ?? upcoming.sorted { ($0.due ?? .distantFuture) < ($1.due ?? .distantFuture) }.first
            ?? open.first
    }
}
