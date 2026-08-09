import SwiftUI
import AppKit
import ServiceManagement

/// The display and dial: status line, the automatic toggle, a per-call
/// override, launch-at-login, and the settings/quit items.
struct MenuBarView: View {
    @ObservedObject var controller: OnAirController

    var body: some View {
        Text(statusLine)

        Divider()

        Toggle("Automatic", isOn: $controller.automationEnabled)

        if controller.micActive {
            Button(controller.overrideThisCall
                   ? "Sign silenced for this call"
                   : "Turn sign off for this call") {
                controller.overrideThisCall.toggle()
            }
        }

        Toggle("Launch at login", isOn: launchAtLogin)

        Divider()

        SettingsLink { Text("Settings...") }
            .keyboardShortcut(",", modifiers: .command)

        Button("Quit On Air") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private var statusLine: String {
        if !controller.automationEnabled { return "Automation paused" }
        if controller.signOn { return "On air" }
        if controller.micActive { return "Mic live, sign held off" }
        return "Off air"
    }

    private var launchAtLogin: Binding<Bool> {
        Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { enabled in
                do {
                    if enabled { try SMAppService.mainApp.register() }
                    else { try SMAppService.mainApp.unregister() }
                } catch {
                    NSLog("Launch-at-login toggle failed: \(error.localizedDescription)")
                }
            })
    }
}
