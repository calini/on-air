import SwiftUI

@main
struct OnAirApp: App {
    @StateObject private var controller = OnAirController()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(controller: controller)
        } label: {
            Image(systemName: iconName)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }

    private var iconName: String {
        if controller.signOn { return "dot.radiowaves.left.and.right" }
        return controller.micActive ? "mic" : "mic.slash"
    }
}
