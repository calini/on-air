import CoreAudio
import Combine

/// The sensor. Watches whether any audio *input* device is actively running,
/// using the same CoreAudio signal that drives the macOS orange recording dot.
///
/// Polls once a second rather than registering property listeners: a listener
/// would also need to re-register every time a device is added or removed, and
/// the poll costs nothing measurable.
final class MicMonitor: ObservableObject {
    @Published private(set) var isActive = false
    private var timer: Timer?

    func start() {
        poll()
        // Add to .common so the timer keeps firing while the menu bar dropdown is
        // open (that switches the main run loop into event-tracking mode, which
        // would otherwise pause a default-mode timer).
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func poll() {
        let active = Self.anyInputRunning()
        if active != isActive {
            DispatchQueue.main.async { self.isActive = active }
        }
    }

    /// True if at least one input device reports it is running somewhere.
    static func anyInputRunning() -> Bool {
        inputDevices().contains { boolProperty($0, kAudioDevicePropertyDeviceIsRunningSomewhere) }
    }

    private static func inputDevices() -> [AudioDeviceID] {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)

        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size) == noErr else { return [] }

        let count = Int(size) / MemoryLayout<AudioDeviceID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &ids) == noErr else { return [] }

        return ids.filter(hasInputStreams)
    }

    /// A device is a microphone (for our purposes) if it has any input streams.
    /// This filters out pure output devices like speakers.
    private static func hasInputStreams(_ device: AudioDeviceID) -> Bool {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain)

        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(device, &addr, 0, nil, &size) == noErr else { return false }
        return size > 0
    }

    private static func boolProperty(_ device: AudioDeviceID,
                                     _ selector: AudioObjectPropertySelector) -> Bool {
        var addr = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)

        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(device, &addr, 0, nil, &size, &value) == noErr else { return false }
        return value != 0
    }
}
