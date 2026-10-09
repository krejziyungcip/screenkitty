import WidgetKit
import SwiftUI
import KittyKit

/// Lock Screen accessory widgets (rectangular / inline / circular).
struct LockScreenWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "com.domin.screenkitty.lock", provider: KittyTimelineProvider()) { entry in
            LockWidgetView(entry: entry)
        }
        .configurationDisplayName("Screen Kitty (Lock Screen)")
        .description("tiny kitty, tiny judgment")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

struct LockWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: KittyEntry

    private var tier: MoodTier { entry.state.mood.tier }
    private var metrics: TaskMetrics { entry.state.metrics(at: entry.date) }

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(inlineText)
        case .accessoryCircular:
            Image(uiImage: KittyWidgetArt.image(tier: tier))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .containerBackground(for: .widget) { Color.clear }
        default:
            rectangular
                .containerBackground(for: .widget) { Color.clear }
        }
    }

    private var inlineText: String {
        metrics.openCount == 0
            ? "kitty: \(tier.label), all done"
            : "kitty: \(tier.label) · \(metrics.openCount) open"
    }

    private var rectangular: some View {
        HStack(spacing: 8) {
            Image(uiImage: KittyWidgetArt.image(tier: tier))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(height: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text("kitty is \(tier.label)")
                    .font(.headline)
                Text(metrics.focusTask?.title ?? "all done — nice")
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
