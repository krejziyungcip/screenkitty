import WidgetKit
import SwiftUI
import ActivityKit
import KittyKit

/// The Dynamic Island + Lock Screen Live Activity presentation.
/// Self-advancing: countdowns use Text(timerInterval:) so the UI stays
/// fresh between updates.
struct KittyActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KittyActivityAttributes.self) { context in
            LockScreenBanner(context: context)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: KittyWidgetArt.aura(for: context.state.tier),
                                   startPoint: .top, endPoint: .bottom)
                }
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(uiImage: KittyWidgetArt.image(tier: context.state.tier))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 36)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.nextTaskTitle ?? "all done")
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 2) {
                        Text(context.state.tier.label)
                            .font(.caption.weight(.semibold))
                        if context.state.streakDays > 0 {
                            Label("\(context.state.streakDays)", systemImage: "flame.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label("\(context.state.openCount) open", systemImage: "checklist")
                            .font(.caption)
                        Spacer()
                        if let due = context.state.nextDue, due > Date() {
                            Text(timerInterval: Date()...due, countsDown: true)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(uiImage: KittyWidgetArt.image(tier: context.state.tier))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 16)
                    .padding(.leading, 2)
            } compactTrailing: {
                if let due = context.state.nextDue, due > Date() {
                    Text(timerInterval: Date()...due, countsDown: true)
                        .font(.caption2.monospacedDigit())
                        .frame(maxWidth: 44)
                } else {
                    Text("\(context.state.openCount)")
                        .font(.caption2.monospacedDigit())
                }
            } minimal: {
                Image(uiImage: KittyWidgetArt.image(tier: context.state.tier))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 16)
            }
        }
    }
}

/// Full banner on the Lock Screen while the activity runs.
private struct LockScreenBanner: View {
    let context: ActivityViewContext<KittyActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            Image(uiImage: KittyWidgetArt.image(tier: context.state.tier))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(context.state.nextTaskTitle ?? "all done — kitty approves")
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text("kitty: \(context.state.tier.label)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if context.state.streakDays > 0 {
                        Label("\(context.state.streakDays)", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            Spacer()
            if let due = context.state.nextDue, due > Date() {
                VStack(spacing: 2) {
                    Text(timerInterval: Date()...due, countsDown: true)
                        .font(.subheadline.monospacedDigit())
                    Text("until due")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
    }
}
