import WidgetKit
import SwiftUI
import KittyKit

/// Home screen widget. Small: kitty + mood. Medium: kitty + focus task
/// with a live countdown and an interactive "done" button.
struct HomeScreenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.domin.screenkitty.home", provider: KittyTimelineProvider()) { entry in
            HomeWidgetView(entry: entry)
        }
        .configurationDisplayName("Screen Kitty")
        .description("the kitty, the mood, the next task")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HomeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: KittyEntry

    private var tier: MoodTier { entry.state.mood.tier }

    var body: some View {
        Group {
            if family == .systemMedium {
                medium
            } else {
                small
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(colors: KittyWidgetArt.aura(for: tier),
                           startPoint: .top, endPoint: .bottom)
        }
    }

    private var small: some View {
        let metrics = entry.state.metrics(at: entry.date)
        return VStack(spacing: 6) {
            Image(uiImage: KittyWidgetArt.image(tier: tier))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(height: 52)
            Text(tier.label)
                .font(.caption.weight(.semibold))
            Text(metrics.openCount == 0 ? "all done" : "\(metrics.openCount) open")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var medium: some View {
        let metrics = entry.state.metrics(at: entry.date)
        let streak = entry.state.mood.streakDays
        return HStack(spacing: 14) {
            Image(uiImage: KittyWidgetArt.image(tier: tier))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(height: 68)

            VStack(alignment: .leading, spacing: 4) {
                Text(metrics.focusTask?.title ?? "nothing left — relax")
                    .font(.headline)
                    .lineLimit(2)
                if let due = metrics.nextDue {
                    Text(timerInterval: entry.date...due, countsDown: true)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text(tier.label + (streak > 0 ? " · \(streak)-day streak" : ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)

            if let focus = metrics.focusTask {
                Button(intent: CompleteTaskIntent()) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                }
                .buttonStyle(.borderless)
            }
        }
    }
}
