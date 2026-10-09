import SwiftUI
import BackgroundTasks

@main
struct ScreenKittyApp: App {
    @StateObject private var controller = KittyController.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Must be registered before the app finishes launching.
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: KittyController.refreshTaskID,
            using: nil
        ) { task in
            Task { @MainActor in
                KittyController.shared.handleBackgroundRefresh()
                task.setTaskCompleted(success: true)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(controller)
                .onAppear { NotificationDelegate.shared.setUp() }
                .onChange(of: scenePhase) { _, phase in
                    controller.handleScenePhase(phase)
                }
        }
    }
}
