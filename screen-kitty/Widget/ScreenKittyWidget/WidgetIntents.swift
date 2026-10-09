import AppIntents
import WidgetKit
import Foundation
import KittyKit

/// The medium home-screen widget's "done" button. Runs in the widget
/// extension process, mutating the shared App Group store directly.
/// (The Dynamic Island refreshes the next time the app foregrounds.)
struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete focus task"
    static var description = IntentDescription("Marks the kitty's current focus task as done.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard var state = AppGroupPaths.load() else {
            return .result(dialog: "kitty lost its brain (no store yet)")
        }
        let now = Date()
        let metrics = TaskMetrics(tasks: state.tasks, at: now)
        guard let focus = metrics.focusTask else {
            return .result(dialog: "nothing left — kitty is impressed")
        }

        let onTime = focus.completedOnTime(at: now)
        state.mood = MoodEngine.applyCompletion(onTime: onTime, to: state.mood, at: now).state
        if let idx = state.tasks.firstIndex(where: { $0.id == focus.id }) {
            state.tasks[idx].completedAt = now
        }
        if TaskMetrics(tasks: state.tasks, at: now).openCount == 0 {
            state.mood = MoodEngine.apply(.allTasksDoneToday, to: state.mood, at: now)
        }

        try AppGroupPaths.save(state)
        WidgetCenter.shared.reloadAllTimelines()
        return .result(dialog: "done. the kitty purrs approvingly")
    }
}
