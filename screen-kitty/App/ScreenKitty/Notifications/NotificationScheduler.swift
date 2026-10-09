import UserNotifications
import KittyKit

/// The only place that talks to UNUserNotificationCenter. Takes pure
/// NagRequests from the planner and turns them into system notifications.
enum NotificationScheduler {
    @discardableResult
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    /// Cancel everything pending and reschedule from a fresh plan.
    /// Deterministic IDs make this cheap and idempotent.
    @discardableResult
    static func sync(state: AppState) async -> Bool {
        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional else { return false }

        let requests = NagPlanner.plan(
            tasks: state.tasks,
            mood: state.mood,
            settings: state.settings,
            now: Date()
        )
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for nag in requests {
            center.add(makeRequest(nag))
        }
        return true
    }

    static func sendTestNag(state: AppState, generator: SassMessageGenerator) async {
        guard await requestAuthorization() else { return }
        let m = state.metrics()
        let context = SassContext(
            nextTaskTitle: m.focusTask?.title,
            openCount: m.openCount,
            overdueCount: m.overdueCount,
            streak: state.mood.streakDays
        )
        let nag = NagRequest(
            id: "test-\(UUID().uuidString)",
            kind: .dailyAnchor,
            priority: 0,
            title: "kitty poke (test)",
            body: generator.message(for: state.mood.tier, context: context, seed: UInt64(Date().timeIntervalSince1970)),
            fireDate: Date()
        )
        UNUserNotificationCenter.current().add(makeRequest(nag))
    }

    // MARK: - Conversion

    static func makeRequest(_ nag: NagRequest) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = nag.title
        content.body = nag.body
        content.sound = .default
        content.threadIdentifier = "screenkitty"

        let trigger: UNNotificationTrigger
        if nag.fireDate.timeIntervalSinceNow <= 1 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: nag.fireDate.timeIntervalSinceNow,
                repeats: false
            )
        }
        return UNNotificationRequest(identifier: nag.id, content: content, trigger: trigger)
    }
}
