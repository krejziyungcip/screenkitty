import SwiftUI

struct RootView: View {
    @EnvironmentObject private var controller: KittyController
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("Kitty", systemImage: "cat.fill") }
                .tag(0)

            TaskListView()
                .tabItem { Label("Tasks", systemImage: "checklist") }
                .tag(1)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(2)
        }
        .tint(Theme.accent(for: controller.tier))
    }
}
