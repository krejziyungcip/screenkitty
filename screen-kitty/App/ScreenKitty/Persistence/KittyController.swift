import SwiftUI
import BackgroundTasks
import WidgetKit
import KittyKit

/// The brain of the app: owns AppState, persists it, and fans every
/// mutation out to widgets, notifications, and the Live Activity.
@MainActor
final class KittyController: ObservableObject {
    static let shared = KittyController()
    static let refreshTaskID = "com.domin.screenkitty.refresh"

    @Published private(set) var state: AppState
    let generator = SassMessageGenerator()

    private init() {
        let loaded = AppGroupPaths.load()
        state = loaded ?? AppState.fresh()
        if loaded == nil {
            try? AppGroupPaths.save(state)
        }
    }

    // MARK: Derived

    var metrics: TaskMetrics { state.metrics() }
    var tier: MoodTier { state.mood.tier }

    func sassBubble(at date: Date = Date()) -> String {
        let m = metrics
        let context = SassContext(
            nextTaskTitle: m.focusTask?.title,
            openCount: m.openCount,
            overdueCount: m.overdueCount,
            streak: state.mood.streakDays
        )
        return generator.bubble(for: tier, context: context, at: date)
    }

    // MARK: Persistence + fan-out

    /// Save to the App Group, refresh widgets, replan notifications,
    /// and refresh the Live Activity. Call after every mutation.
    func persist() {
        try? AppGroupPaths.save(state)
        WidgetCenter.shared.reloadAllTimelines()

        let snapshot = state
        Task.detached(priority: .utility) {
            await NotificationScheduler.sync(state: snapshot)
        }
        KittyActivityController.shared.refresh(state: state)
    }

    // MARK: Scene lifecycle

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // Widget intents may have changed the store behind our back.
            if let fresh = AppGroupPaths.load(), fresh != state {
                state = fresh
            }
            let now = Date()
            state.mood = MoodEngine.apply(.appOpened, to: state.mood, at: now)
            persist()

        case .background:
            KittyActivityController.shared.handleBackground(state: state)
            scheduleBackgroundRefresh()

        default:
            break
        }
    }

    func handleBackgroundRefresh() {
        KittyActivityController.shared.refresh(state: state)
        let snapshot = state
        Task.detached(priority: .utility) {
            await NotificationScheduler.sync(state: snapshot)
        }
        scheduleBackgroundRefresh()
    }

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    // MARK: Tasks

    func addTask(title: String, due: Date?) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.tasks.append(KittyTask(title: trimmed, due: due, createdAt: Date()))
        persist()
    }

    func completeTask(_ id: UUID) {
        guard let idx = state.tasks.firstIndex(where: { $0.id == id }),
              state.tasks[idx].completedAt == nil else { return }
        let now = Date()
        let onTime = state.tasks[idx].completedOnTime(at: now)

        let result = MoodEngine.applyCompletion(onTime: onTime, to: state.mood, at: now)
        state.mood = result.state
        state.tasks[idx].completedAt = now

        if state.metrics(at: now).openCount == 0 {
            state.mood = MoodEngine.apply(.allTasksDoneToday, to: state.mood, at: now)
        }
        persist()
    }

    func uncompleteTask(_ id: UUID) {
        guard let idx = state.tasks.firstIndex(where: { $0.id == id }) else { return }
        state.tasks[idx].completedAt = nil
        persist()
    }

    func deleteTask(_ id: UUID) {
        state.tasks.removeAll { $0.id == id }
        persist()
    }

    // MARK: Settings

    func setAnchorHour(_ hour: Int) {
        state.settings.anchorHour = hour
        persist()
    }

    func setMaxNagsPerDay(_ n: Int) {
        state.settings.maxNagsPerDay = n
        persist()
    }

    func resetMood() {
        state.mood = MoodState(lastUpdated: Date())
        persist()
    }

    // MARK: Notifications

    func requestNotificationAccess() async -> Bool {
        await NotificationScheduler.requestAuthorization()
    }

    func sendTestNag() async {
        await NotificationScheduler.sendTestNag(state: state, generator: generator)
    }
}
