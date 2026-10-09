import WidgetKit
import SwiftUI

@main
struct ScreenKittyWidgetBundle: WidgetBundle {
    var body: some Widget {
        HomeScreenWidget()
        LockScreenWidget()
        KittyActivityWidget()
    }
}
