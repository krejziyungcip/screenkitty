import XCTest
@testable import KittyKit

final class NagPlannerTests: XCTestCase {
    /// Fixed at 09:00 local time so anchor/streak nags (20:00/19:30) are
    /// always in the future regardless of the runner's timezone.
    let now = Calendar.current.date(
        bySettingHour: 9, minute: 0, second: 0,
        of: Date(timeIntervalSinceReferenceDate: 800_000_000)
    )!
    var calendar: Calendar { .current }

    func settings(anchorHour: Int = 20, maxPerDay: Int = 4) -> NagSettings {
        NagSettings(anchorHour: anchorHour, maxNagsPerDay: maxPerDay, planningHorizonDays: 3)
    }

    // MARK: Due reminders

    func testFutureDueTaskGetsReminder() {
        let due = now.addingTimeInterval(3600)
        let task = KittyTask(title: "report", due: due, createdAt: now)
        let requests = NagPlanner.plan(tasks: [task], mood: MoodState(lastUpdated: now),
                                       settings: settings(), now: now, calendar: calendar)

        let reminder = requests.first { $0.kind == .dueReminder }
        XCTAssertNotNil(reminder)
        XCTAssertEqual(reminder?.fireDate, due)
        XCTAssertEqual(reminder?.id, "due-\(task.id.uuidString)")
        XCTAssertTrue(reminder?.body.contains("report") ?? false)
    }

    func testTaskWithoutDueGetsNoReminder() {
        let task = KittyTask(title: "chill", createdAt: now)
        let requests = NagPlanner.plan(tasks: [task], mood: MoodState(lastUpdated: now),
                                       settings: settings(), now: now, calendar: calendar)
        XCTAssertFalse(requests.contains { $0.kind == .dueReminder })
    }

    func testReminderBeyondHorizonIsSkipped() {
        let far = now.addingTimeInterval(10 * 86400)
        let task = KittyTask(title: "someday", due: far, createdAt: now)
        let requests = NagPlanner.plan(tasks: [task], mood: MoodState(lastUpdated: now),
                                       settings: settings(), now: now, calendar: calendar)
        XCTAssertFalse(requests.contains { $0.kind == .dueReminder })
    }

    // MARK: Overdue escalations

    func testOverdueTaskGetsEscalations() {
        let due = now.addingTimeInterval(-3600)
        let task = KittyTask(title: "old", due: due, createdAt: now)
        let requests = NagPlanner.plan(tasks: [task], mood: MoodState(lastUpdated: now),
                                       settings: settings(), now: now, calendar: calendar)

        let escalations = requests.filter { $0.kind == .overdueEscalation }
        XCTAssertEqual(escalations.count, 2) // 30min and 2h, both in the future
        XCTAssertTrue(escalations.allSatisfy { $0.fireDate > now })
        XCTAssertTrue(escalations.allSatisfy { $0.id.hasPrefix("over-") })
    }

    func testEscalationNotDuplicatedWhenAlreadyFired() {
        // Overdue by 4 hours: the 30m and 2h pings are in the past — skip.
        let due = now.addingTimeInterval(-4 * 3600)
        let task = KittyTask(title: "ancient", due: due, createdAt: now)
        let requests = NagPlanner.plan(tasks: [task], mood: MoodState(lastUpdated: now),
                                       settings: settings(), now: now, calendar: calendar)
        XCTAssertFalse(requests.contains { $0.kind == .overdueEscalation })
    }

    // MARK: Daily anchor

    func testDailyAnchorScheduledWhenOpenTasksExist() {
        let task = KittyTask(title: "stuff", createdAt: now)
        let requests = NagPlanner.plan(tasks: [task], mood: MoodState(lastUpdated: now),
                                       settings: settings(anchorHour: 21), now: now, calendar: calendar)

        let anchors = requests.filter { $0.kind == .dailyAnchor }
        XCTAssertFalse(anchors.isEmpty)
        // All anchors land at 21:00 local time.
        XCTAssertTrue(anchors.allSatisfy {
            calendar.component(.hour, from: $0.fireDate) == 21
        })
    }

    func testNoAnchorWhenNothingOpen() {
        let done = KittyTask(title: "done", completedAt: now, createdAt: now)
        let requests = NagPlanner.plan(tasks: [done], mood: MoodState(lastUpdated: now),
                                       settings: settings(), now: now, calendar: calendar)
        XCTAssertTrue(requests.isEmpty)
    }

    // MARK: Streak at risk

    func testStreakAtRiskFiresWhenStreakAliveAndNothingDoneToday() {
        let yesterday = now.addingTimeInterval(-86400)
        let mood = MoodState(lastUpdated: now, streakDays: 5, lastStreakDay: yesterday)
        let task = KittyTask(title: "keep it alive", createdAt: now)
        let requests = NagPlanner.plan(tasks: [task], mood: mood, settings: settings(), now: now, calendar: calendar)

        XCTAssertTrue(requests.contains { $0.kind == .streakAtRisk })
    }

    func testNoStreakNagWithoutStreak() {
        let mood = MoodState(lastUpdated: now, streakDays: 0, lastStreakDay: nil)
        let task = KittyTask(title: "whatever", createdAt: now)
        let requests = NagPlanner.plan(tasks: [task], mood: mood, settings: settings(), now: now, calendar: calendar)
        XCTAssertFalse(requests.contains { $0.kind == .streakAtRisk })
    }

    // MARK: Caps

    func testPerDayCapIsRespected() {
        var tasks: [KittyTask] = []
        for i in 0..<30 {
            tasks.append(KittyTask(title: "t\(i)", due: now.addingTimeInterval(Double(i) * 600), createdAt: now))
        }
        let requests = NagPlanner.plan(tasks: tasks, mood: MoodState(lastUpdated: now),
                                       settings: settings(maxPerDay: 2), now: now, calendar: calendar)

        var perDay: [String: Int] = [:]
        for r in requests { perDay[DayMath.dayKey(r.fireDate, calendar: calendar), default: 0] += 1 }
        XCTAssertTrue(perDay.values.allSatisfy { $0 <= 2 })
    }

    func testGlobalCapIsRespected() {
        var tasks: [KittyTask] = []
        for i in 0..<60 {
            tasks.append(KittyTask(title: "t\(i)", due: now.addingTimeInterval(Double(i) * 3600), createdAt: now))
        }
        let requests = NagPlanner.plan(tasks: tasks, mood: MoodState(lastUpdated: now),
                                       settings: settings(maxPerDay: 10), now: now, calendar: calendar)
        XCTAssertLessThanOrEqual(requests.count, NagPlanner.globalCap)
    }

    func testPlanIsDeterministic() {
        var tasks: [KittyTask] = []
        for i in 0..<12 {
            tasks.append(KittyTask(title: "t\(i)", due: now.addingTimeInterval(Double(i) * 5400), createdAt: now))
        }
        let mood = MoodState(lastUpdated: now, streakDays: 3)
        let a = NagPlanner.plan(tasks: tasks, mood: mood, settings: settings(), now: now, calendar: calendar)
        let b = NagPlanner.plan(tasks: tasks, mood: mood, settings: settings(), now: now, calendar: calendar)
        XCTAssertEqual(a, b)
    }

    func testCompletedTasksProduceNothing() {
        let done = KittyTask(title: "done", due: now.addingTimeInterval(3600), completedAt: now, createdAt: now)
        let requests = NagPlanner.plan(tasks: [done], mood: MoodState(lastUpdated: now),
                                       settings: settings(), now: now, calendar: calendar)
        XCTAssertTrue(requests.isEmpty)
    }
}
