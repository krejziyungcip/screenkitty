import WidgetKit
import Foundation
import KittyKit

/// One widget render: a snapshot of the kitty's brain.
struct KittyEntry: TimelineEntry {
    let date: Date
    let state: AppState
}

/// Produces 12 hourly entries in a single timeline — the mood visibly
/// decays across the day without spending the reload budget. Reloads
/// after the last entry or sooner if the app asks.
struct KittyTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> KittyEntry {
        KittyEntry(date: Date(), state: AppState.fresh())
    }

    func getSnapshot(in context: Context, completion: @escaping (KittyEntry) -> Void) {
        completion(KittyEntry(date: Date(), state: AppGroupPaths.load() ?? AppState.fresh()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KittyEntry>) -> Void) {
        let base = AppGroupPaths.load() ?? AppState.fresh()
        let now = Date()

        var entries: [KittyEntry] = []
        for hour in 0..<12 {
            let date = now.addingTimeInterval(Double(hour) * 3600)
            var state = base
            state.mood = MoodEngine.decay(base.mood, at: date)
            entries.append(KittyEntry(date: date, state: state))
        }
        completion(Timeline(entries: entries, policy: .after(entries.last!.date.addingTimeInterval(1800))))
    }
}

/// Widget-target helpers: static kitty frames and mood colors.
enum KittyWidgetArt {
    static func image(tier: MoodTier, frameIndex: Int = 0) -> UIImage {
        PixelCGRenderer.image(for: KittyFrames.frames(for: tier)[frameIndex % 2])
    }

    static func aura(for tier: MoodTier) -> [Color] {
        switch tier {
        case .happy:
            return [Color(red: 1.00, green: 0.94, blue: 0.82), Color(red: 0.99, green: 0.82, blue: 0.60)]
        case .content:
            return [Color(red: 0.88, green: 0.94, blue: 0.84), Color(red: 0.72, green: 0.86, blue: 0.72)]
        case .uneasy:
            return [Color(red: 0.86, green: 0.90, blue: 0.96), Color(red: 0.70, green: 0.79, blue: 0.90)]
        case .grumpy:
            return [Color(red: 0.88, green: 0.87, blue: 0.89), Color(red: 0.72, green: 0.70, blue: 0.74)]
        case .furious:
            return [Color(red: 0.96, green: 0.85, blue: 0.82), Color(red: 0.90, green: 0.62, blue: 0.58)]
        }
    }

    static func context(for entry: KittyEntry) -> SassContext {
        let m = entry.state.metrics(at: entry.date)
        return SassContext(
            nextTaskTitle: m.focusTask?.title,
            openCount: m.openCount,
            overdueCount: m.overdueCount,
            streak: entry.state.mood.streakDays
        )
    }
}
