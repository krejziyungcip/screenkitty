import ActivityKit
import Foundation
import KittyKit

/// Owns the Dynamic Island / Lock Screen Live Activity.
///
/// Freshness strategy without push: the widget UI self-advances via
/// Text(timerInterval:), so real updates only happen on foregrounds,
/// task completions, and best-effort background refreshes. staleDate is
/// set honestly so the system grays out a stale kitty instead of lying.
@MainActor
final class KittyActivityController {
    static let shared = KittyActivityController()

    private init() {}

    // MARK: Lifecycle

    /// Called on backgrounding: start the activity if there's work to do.
    func handleBackground(state: AppState) {
        let metrics = state.metrics()
        guard metrics.openCount > 0 else {
            endAll()
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        if Activity<KittyActivityAttributes>.activities.isEmpty {
            start(state: state)
        } else {
            update(state: state)
        }
    }

    /// Called after every mutation. Starts nothing new; ends on all-done.
    func refresh(state: AppState) {
        let metrics = state.metrics()
        if metrics.openCount == 0 {
            endWithCelebration(state: state)
        } else if !Activity<KittyActivityAttributes>.activities.isEmpty {
            update(state: state)
        }
    }

    private func start(state: AppState) {
        let content = makeContent(state: state)
        _ = try? Activity.request(
            attributes: KittyActivityAttributes(),
            content: content,
            pushType: nil
        )
    }

    private func update(state: AppState) {
        let content = makeContent(state: state)
        for activity in Activity<KittyActivityAttributes>.activities {
            Task { try? await activity.update(content) }
        }
    }

    func endAll() {
        for activity in Activity<KittyActivityAttributes>.activities {
            Task { try? await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    private func endWithCelebration(state: AppState) {
        let content = makeContent(state: state)
        let dismissAt = Date().addingTimeInterval(120)
        for activity in Activity<KittyActivityAttributes>.activities {
            Task {
                try? await activity.end(content, dismissalPolicy: .after(dismissAt))
            }
        }
    }

    // MARK: Content

    private func makeContent(state: AppState) -> ActivityContent<KittyActivityAttributes.ContentState> {
        let now = Date()
        let metrics = state.metrics()
        let contentState = KittyActivityAttributes.ContentState(
            tier: state.mood.tier,
            openCount: metrics.openCount,
            overdueCount: metrics.overdueCount,
            streakDays: state.mood.streakDays,
            nextTaskTitle: metrics.focusTask?.title,
            nextDue: metrics.nextDue
        )
        // Honest staleness: never claim freshness past 8h or past the next due date.
        let stale = min(metrics.nextDue ?? now.addingTimeInterval(4 * 3600),
                        now.addingTimeInterval(8 * 3600))
        return ActivityContent(state: contentState, staleDate: stale)
    }
}
