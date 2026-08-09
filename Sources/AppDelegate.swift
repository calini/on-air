import AppKit
import Combine
import ServiceManagement

/// Owns the menu bar item. SwiftUI's `MenuBarExtra` cannot distinguish left
/// from right click, so the status item is driven directly via AppKit:
/// left click flips the sign manually, right click shows the menu.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = OnAirController()

    private var statusItem: NSStatusItem!
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        Publishers.CombineLatest(controller.$signOn, controller.$micActive)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in self?.updateIcon() }
            .store(in: &cancellables)
        updateIcon()
    }

    private func updateIcon() {
        let name = controller.signOn ? "dot.radiowaves.left.and.right" : (controller.micActive ? "mic" : "mic.slash")
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "On Air")
        image?.isTemplate = true
        statusItem.button?.image = image
    }

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent, let button = statusItem.button else { return }

        if event.type == .rightMouseUp {
            buildMenu().popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
        } else {
            controller.manualToggle()
        }
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let status = NSMenuItem(title: statusLine, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())

        let automatic = NSMenuItem(title: "Automatic", action: #selector(toggleAutomatic), keyEquivalent: "")
        automatic.target = self
        automatic.state = controller.automationEnabled ? .on : .off
        menu.addItem(automatic)

        if controller.micActive {
            let title = controller.overrideThisCall ? "Sign silenced for this call" : "Turn sign off for this call"
            let overrideItem = NSMenuItem(title: title, action: #selector(toggleOverride), keyEquivalent: "")
            overrideItem.target = self
            menu.addItem(overrideItem)
        }

        let launch = NSMenuItem(title: "Launch at login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launch.target = self
        launch.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launch)

        menu.addItem(.separator())

        let settings = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let quit = NSMenuItem(title: "Quit On Air", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        return menu
    }

    private var statusLine: String {
        if !controller.automationEnabled { return "Automation paused" }
        if controller.signOn { return "On air" }
        if controller.micActive { return "Mic live, sign held off" }
        return "Off air"
    }

    @objc private func toggleAutomatic() {
        controller.automationEnabled.toggle()
    }

    @objc private func toggleOverride() {
        controller.overrideThisCall.toggle()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Launch-at-login toggle failed: \(error.localizedDescription)")
        }
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        // SwiftUI's Settings scene registers this responder action; there is
        // no public API to trigger it from outside a SwiftUI view.
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
