import Foundation

/// Plans every future notification the kitty will send.
///
/// Pure function: (tasks, mood, settings, now) -> [NagRequest].
/// iOS caps pending local notifications at 64; the planner keeps a rolling
/// window of at most 40, sorted and trimmed deterministically. The app
/// re-plans on every foreground, cancelling and rescheduling by ID.
public enum NagPlanner {
    public static let globalCap = 40

    public static func plan(
        tasks: [KittyTask],
        mood: MoodState,
        settings: NagSettings,
        now: Date,
        calendar: Calendar = .current,
        generator: SassMessageGenerator = SassMessageGenerator()
    ) -> [NagRequest] {
        let metrics = TaskMetrics(tasks: tasks, at: now, calendar: calendar)
        let tier = mood.tier
        let hour = calendar.component(.hour, from: now)
        var requests: [NagRequest] = []

        // Per-task context for sass.
        func contextFor(_ task: KittyTask?) -> SassContext {
            SassContext(
                nextTaskTitle: task?.title,
                openCount: metrics.openCount,
                overdueCount: metrics.overdueCount,
                streak: mood.streakDays
            )
        }

        // 1. Due reminders + overdue escalations.
        let horizon = calendar.date(byAdding: .day, value: settings.planningHorizonDays, to: now) ?? now
        for task in tasks where !task.isCompleted {
            guard let due = task.due else { continue }

            if due > now && due <= horizon {
                let ctx = contextFor(task)
                requests.append(NagRequest(
                    id: "due-\(task.id.uuidString)",
                    kind: .dueReminder,
                    priority: 0,
                    title: generator.title(for: tier, at: due, calendar: calendar),
                    body: generator.message(for: tier, context: ctx, seed: seedFor(task: task, date: due)),
                    fireDate: due
                ))
            }

            if due <= now {
                for (idx, offset) in settings.overdueEscalations.enumerated() {
                    let fire = due.addingTimeInterval(offset)
                    guard fire > now, fire <= horizon.addingTimeInterval(86400) else { continue }
                    let ctx = contextFor(task)
                    requests.append(NagRequest(
                        id: "over-\(task.id.uuidString)-\(idx)",
                        kind: .overdueEscalation,
                        priority: 1,
                        title: generator.title(for: tier, at: fire, calendar: calendar),
                        body: generator.message(for: tier, context: ctx, seed: seedFor(task: task, date: fire)),
                        fireDate: fire
                    ))
                }
            }
        }

        // 2. Daily anchor nag ("wrap it up" hour) for each day in the horizon.
        //    Non-repeating: the next foreground re-plans and drops days that
        //    end up fully done.
        if metrics.openCount > 0 {
            for dayOffset in 0..<max(1, settings.planningHorizonDays) {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
                let fire = DayMath.date(day, hour: settings.anchorHour, calendar: calendar)
                guard fire > now else { continue }
                let ctx = contextFor(metrics.focusTask)
                requests.append(NagRequest(
                    id: "anchor-\(DayMath.dayKey(day, calendar: calendar))",
                    kind: .dailyAnchor,
                    priority: 2,
                    title: generator.title(for: tier, at: fire, calendar: calendar),
                    body: generator.message(for: tier, context: ctx, seed: seedFor(task: nil, date: fire)),
                    fireDate: fire
                ))
            }
        }

        // 3. Streak-at-risk: streak alive, nothing done today, evening heads-up
        //    one hour before the anchor.
        let todayDone = metrics.completedToday > 0
        if mood.streakDays >= 2 && !todayDone {
            let fire = DayMath.date(now, hour: max(0, settings.anchorHour - 1), minute: 30, calendar: calendar)
            if fire > now {
                let ctx = contextFor(metrics.focusTask)
                requests.append(NagRequest(
                    id: "streak-\(DayMath.dayKey(now, calendar: calendar))",
                    kind: .streakAtRisk,
                    priority: 3,
                    title: "the streak is in danger",
                    body: generator.message(for: tier, context: ctx, seed: seedFor(task: nil, date: fire)),
                    fireDate: fire
                ))
            }
        }

        return trimmed(requests, settings: settings, now: now, calendar: calendar)
    }

    // MARK: - Caps

    static func trimmed(
        _ requests: [NagRequest],
        settings: NagSettings,
        now: Date,
        calendar: Calendar
    ) -> [NagRequest] {
        // Per-day cap: keep the most important nags per calendar day.
        var byDay: [String: [NagRequest]] = [:]
        for r in requests {
            byDay[DayMath.dayKey(r.fireDate, calendar: calendar), default: []].append(r)
        }
        let capped = byDay.flatMap { _, list -> [NagRequest] in
            let sorted = list.sorted { lhs, rhs in
                if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
                if lhs.fireDate != rhs.fireDate { return lhs.fireDate < rhs.fireDate }
                return lhs.id < rhs.id
            }
            return Array(sorted.prefix(max(1, settings.maxNagsPerDay)))
        }

        // Global cap: soonest first.
        return Array(capped.sorted { $0.fireDate < $1.fireDate }.prefix(globalCap))
    }

    static func seedFor(task: KittyTask?, date: Date) -> UInt64 {
        var h: UInt64 = 0xFEEDFACE
        if let id = task?.id.uuidString.utf8 {
            for byte in id { h = (h ^ UInt64(byte)) &* 0x100000001B3 }
        }
        return h &+ UInt64(bitPattern: Int64(date.timeIntervalSinceReferenceDate.rounded()))
    }
}
