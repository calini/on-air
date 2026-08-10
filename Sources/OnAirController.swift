import Foundation
import Combine

/// The policy layer. Decides what the sign *should* be doing, given the mic
/// signal, the automation toggle, and any manual override, then drives the
/// Home Assistant actuator to match.
///
/// Desired sign state = automation on AND mic live AND not overridden.
/// When the mic goes quiet, the "off" is delayed a few seconds so the sign
/// does not flicker between back-to-back meetings. Manual actions are instant.
@MainActor
final class OnAirController: ObservableObject {
    @Published var automationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(automationEnabled, forKey: "automationEnabled")
            reconcile()
        }
    }
    @Published private(set) var micActive = false
    @Published private(set) var signOn = false

    /// Silences the sign for the current call only. Clears itself automatically
    /// once the mic goes quiet, so you cannot forget it is set.
    @Published var overrideThisCall = false {
        didSet { reconcile() }
    }

    /// Direct manual flip of the actuator (left-click on the menu bar icon),
    /// independent of the automation policy. The next mic transition still
    /// reconciles as usual, so this only holds until then.
    func manualToggle() {
        apply(!signOn)
    }

    private let monitor = MicMonitor()
    private var cancellables = Set<AnyCancellable>()
    private var pendingOff: DispatchWorkItem?
    private let offDelay: TimeInterval = 3

    init() {
        automationEnabled = UserDefaults.standard.object(forKey: "automationEnabled") as? Bool ?? true

        monitor.$isActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] active in self?.micChanged(to: active) }
            .store(in: &cancellables)

        monitor.start()
    }

    private func micChanged(to active: Bool) {
        micActive = active
        if active {
            reconcile(immediate: true)
        } else {
            if overrideThisCall { overrideThisCall = false } // clears override (its didSet reconciles)
            reconcile(immediate: false)                       // delayed off to avoid flicker
        }
    }

    private func reconcile(immediate: Bool = true) {
        let desired = automationEnabled && micActive && !overrideThisCall

        pendingOff?.cancel()
        pendingOff = nil

        if desired {
            if !signOn { apply(true) }
            return
        }

        guard signOn else { return }

        if immediate {
            apply(false)
        } else {
            let work = DispatchWorkItem { [weak self] in
                self?.pendingOff = nil
                self?.apply(false)
            }
            pendingOff = work
            DispatchQueue.main.asyncAfter(deadline: .now() + offDelay, execute: work)
        }
    }

    private func apply(_ on: Bool) {
        signOn = on
        guard let ha = HomeAssistant.fromDefaults() else { return }
        Task { await ha.setSwitch(on: on) }
    }
}
