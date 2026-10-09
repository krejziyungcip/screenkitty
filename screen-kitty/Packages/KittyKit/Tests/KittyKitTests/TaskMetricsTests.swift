import XCTest
@testable import KittyKit

final class TaskMetricsTests: XCTestCase {
    let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    func testCounts() {
        let tasks = [
            KittyTask(title: "overdue", due: now.addingTimeInterval(-3600), createdAt: now),
            KittyTask(title: "upcoming", due: now.addingTimeInterval(3600), createdAt: now),
            KittyTask(title: "noDue", createdAt: now),
            KittyTask(title: "doneToday", completedAt: now.addingTimeInterval(-60), createdAt: now),
            KittyTask(title: "doneYesterday", completedAt: now.addingTimeInterval(-86400), createdAt: now),
        ]
        let m = TaskMetrics(tasks: tasks, at: now)
        XCTAssertEqual(m.openCount, 3)
        XCTAssertEqual(m.overdueCount, 1)
        XCTAssertEqual(m.completedToday, 1)
        XCTAssertEqual(m.nextDue, now.addingTimeInterval(3600))
    }

    func testFocusTaskPrefersOverdue() {
        let overdue = KittyTask(title: "old", due: now.addingTimeInterval(-7200), createdAt: now)
        let upcoming = KittyTask(title: "new", due: now.addingTimeInterval(600), createdAt: now)
        let m = TaskMetrics(tasks: [upcoming, overdue], at: now)
        XCTAssertEqual(m.focusTask?.title, "old")
    }

    func testFocusTaskFallsBackToOpenWithoutDue() {
        let loose = KittyTask(title: "loose", createdAt: now)
        let m = TaskMetrics(tasks: [loose], at: now)
        XCTAssertEqual(m.focusTask?.title, "loose")
        XCTAssertNil(m.nextDue)
    }

    func testOverdueHelper() {
        let task = KittyTask(title: "t", due: now.addingTimeInterval(-1), createdAt: now)
        XCTAssertTrue(task.isOverdue(at: now))
        XCTAssertTrue(task.completedOnTime(at: now) == false)

        let done = KittyTask(title: "t", due: now.addingTimeInterval(-1), completedAt: now, createdAt: now)
        XCTAssertFalse(done.isOverdue(at: now))
    }
}
