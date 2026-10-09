import SwiftUI
import UserNotifications
import KittyKit

struct SettingsView: View {
    @EnvironmentObject private var controller: KittyController

    @State private var authStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            Form {
                Section("nag schedule") {
                    Picker("evening nag at", selection: Binding(
                        get: { controller.state.settings.anchorHour },
                        set: { controller.setAnchorHour($0) }
                    )) {
                        ForEach(6...23, id: \.self) { hour in
                            Text(hourLabel(hour)).tag(hour)
                        }
                    }
                    Stepper(
                        "max nags per day: \(controller.state.settings.maxNagsPerDay)",
                        value: Binding(
                            get: { controller.state.settings.maxNagsPerDay },
                            set: { controller.setMaxNagsPerDay($0) }
                        ),
                        in: 1...8
                    )
                }

                Section("notifications") {
                    Text(statusText)
                        .foregroundStyle(.secondary)
                    if authStatus != .authorized {
                        Button("allow nagging") {
                            Task {
                                let granted = await controller.requestNotificationAccess()
                                authStatus = granted ? .authorized : .denied
                            }
                        }
                    }
                    Button("send a test nag") {
                        Task { await controller.sendTestNag() }
                    }
                }

                Section("kitty mood") {
                    LabeledContent("score", value: "\(Int(controller.state.mood.score))")
                    LabeledContent("mood", value: controller.tier.label)
                    Button("reset mood", role: .destructive) {
                        controller.resetMood()
                    }
                }

                Section("about") {
                    LabeledContent("app group", value: AppGroupPaths.hasContainer ? "ok" : "MISSING (widget sync broken)")
                    LabeledContent("bundle version", value: versionString)
                    Text("Screen Kitty is a pixel guilt machine. It gets sad when you slack off and delighted when you don't. That's the whole business model.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .task { authStatus = await NotificationScheduler.authorizationStatus() }
        }
    }

    private var statusText: String {
        switch authStatus {
        case .authorized: return "the kitty is licensed to nag."
        case .denied: return "notifications denied — nags will only appear in-app."
        case .notDetermined: return "permission not asked yet."
        default: return "notifications unavailable."
        }
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    private func hourLabel(_ hour: Int) -> String {
        String(format: "%02d:00", hour)
    }
}
