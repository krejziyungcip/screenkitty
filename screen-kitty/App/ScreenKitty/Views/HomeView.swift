import SwiftUI
import UserNotifications
import KittyKit

/// The kitty's home: mood aura, sass bubble, streak, and the next task
/// with a one-tap "did it" button.
struct HomeView: View {
    @EnvironmentObject private var controller: KittyController
    @State private var authStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: Theme.aura(for: controller.tier),
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        sassBubble
                        KittyStageView(tier: controller.tier)
                        moodRow
                        nextTaskCard
                        if needsAuthBanner { authBanner }
                    }
                    .padding()
                }
            }
            .navigationTitle("Screen Kitty")
            .task { authStatus = await NotificationScheduler.authorizationStatus() }
        }
    }

    // MARK: Pieces

    /// Re-evaluated every 30 seconds so the kitty says new things over time,
    /// but stays stable within each window (seeded by hour).
    private var sassBubble: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            Text(controller.sassBubble(at: context.date))
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                .overlay(alignment: .bottomTrailing) {
                    Circle().fill(.thinMaterial).frame(width: 12, height: 12)
                        .offset(x: -18, y: 8)
                }
        }
    }

    private var moodRow: some View {
        HStack(spacing: 12) {
            Label(controller.tier.label, systemImage: "face.smiling.inverse")
                .font(.headline)
            if controller.state.mood.streakDays > 0 {
                Label("\(controller.state.mood.streakDays)-day streak", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Capsule().fill(.thinMaterial))
    }

    private var nextTaskCard: some View {
        Group {
            if let focus = controller.metrics.focusTask {
                VStack(alignment: .leading, spacing: 10) {
                    Text("next up")
                        .font(.caption)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                    Text(focus.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    if let due = focus.due {
                        Label(dueText(due, overdue: focus.isOverdue()), systemImage: "clock")
                            .font(.subheadline)
                            .foregroundStyle(focus.isOverdue() ? .red : .secondary)
                    }
                    Button {
                        controller.completeTask(focus.id)
                    } label: {
                        Label("I did it", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent(for: controller.tier))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.accent(for: controller.tier))
                    Text("nothing left. the kitty approves.")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
            }
        }
    }

    private var needsAuthBanner: Bool {
        authStatus == .denied || authStatus == .notDetermined
    }

    private var authBanner: some View {
        Button {
            Task {
                let granted = await controller.requestNotificationAccess()
                authStatus = granted ? .authorized : .denied
            }
        } label: {
            Label(
                authStatus == .denied
                    ? "notifications are off — the kitty can't nag you"
                    : "let the kitty nag you",
                systemImage: "bell.badge"
            )
        }
        .font(.footnote)
    }

    private func dueText(_ due: Date, overdue: Bool) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let relative = formatter.localizedString(for: due, relativeTo: Date())
        return overdue ? "overdue \(relative)" : "due \(relative)"
    }
}
