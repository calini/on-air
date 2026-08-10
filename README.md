# On Air

<p align="center"><img src="icon.png" alt="On Air app icon" width="300"></p>

<p align="center">
  <a href="https://github.com/calini/on-air/actions/workflows/release.yml"><img src="https://github.com/calini/on-air/actions/workflows/release.yml/badge.svg" alt="Build & Release"></a>
  <a href="https://github.com/calini/on-air/releases/latest"><img src="https://img.shields.io/github/v/release/calini/on-air" alt="Latest release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/calini/on-air" alt="License"></a>
</p>

A tiny macOS menu bar app that turns a Home Assistant switch on while you are in
a call, and off when you are not. Point it at the switch controlling your neon
"On Air" sign and forget about it.

It works like a thermostat. A sensor reads the room (is any microphone live), a
small policy layer decides what should happen (automatic on/off, minus any
manual override), and an actuator flips the switch (a Home Assistant REST call).
The menu bar item is the thermostat's little display and dial.

## How detection works

Instead of trying to recognise Zoom, Teams, Meet and friends individually, the
app watches one CoreAudio signal: [`kAudioDevicePropertyDeviceIsRunningSomewhere`](https://developer.apple.com/documentation/coreaudio/kaudiodevicepropertydeviceisrunningsomewhere).
That is the same signal behind the orange recording dot in the macOS menu bar,
so any app that opens the mic trips it. Detection is therefore app-agnostic and
needs no microphone permission, because it reads device state, not audio.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Quick start

```sh
make open          # generates the Xcode project and opens it
```

Then in Xcode:

1. Select the `OnAir` target, open Signing & Capabilities, and pick your
   team (or set `DEVELOPMENT_TEAM` in `project.yml`).
2. Build and run. A small microphone icon appears in the menu bar.
3. Open Settings from the menu and fill in your Home Assistant details (below).

To build a Release binary from the command line once signing is set:

```sh
make build
```

The generated `.xcodeproj` and `Config/Info.plist` are not committed. `project.yml`
is the source of truth: run `make generate` (or `xcodegen generate`) to recreate
them on a fresh clone.

## Configuration

Open **Settings** from the menu bar item and provide three things:

- **Base URL**: e.g. `http://homeassistant.local:8123` or your HTTPS URL.
- **Switch entity ID**: e.g. `switch.on_air_sign`. Find it in Home Assistant
  under Settings > Devices & Services > Entities.
- **Long-lived access token**: create one from your Home Assistant profile page
  (Security tab, bottom of the page). See the
  [REST API docs](https://developers.home-assistant.io/docs/api/rest/). The token
  is stored in your login Keychain, not in plain preferences.

## Using it

The menu bar icon reflects state at a glance:

- `mic.slash`: off air, mic idle
- `mic`: mic is live but the sign is being held off (override or automation paused)
- `dot.radiowaves.left.and.right`: on air, sign is on

Menu items:

- **Automatic**: master switch for the whole automation.
- **Turn sign off for this call**: silence the sign for the current call only. It
  re-arms automatically once the call ends.
- **Launch at login**: registers the app via [`SMAppService`](https://developer.apple.com/documentation/servicemanagement/smappservice).
  This works reliably only when the app is built and run as a proper bundle (drag
  it to `/Applications`), not from Xcode's build folder.

## Caveats worth knowing

- **Bluetooth mics are the weak spot.** Some Bluetooth input devices report as
  never running for this property, so if you take calls on AirPods, test that
  setup first. Built-in and wired/USB mics are reliable.
- **Any mic use trips it**, not just calls: dictation, Voice Memos, a browser tab
  grabbing the mic. For an on-air sign that is usually the behaviour you want.
- **Local HTTP is allowed** via `NSAllowsLocalNetworking` in `project.yml`. If you
  front Home Assistant with HTTPS you can drop that key.

## Releases

Pushing a tag like `v0.2.0` triggers [`.github/workflows/release.yml`](.github/workflows/release.yml),
which builds an **ad-hoc signed** `OnAir.zip` and attaches it to a GitHub
Release. Ad-hoc signing needs no Apple Developer account, but it also isn't
notarized, so Gatekeeper will flag it on first launch:

1. Unzip and drag `OnAir.app` to `/Applications`.
2. Right-click (or Control-click) it and choose **Open**, then confirm in the
   dialog. This is only needed once — after that it launches normally. (Plain
   double-click will just say the developer cannot be verified, with no
   option to override.)

To build the same ad-hoc signed zip locally: `make release`.

If this ever needs to run on machines you don't control (or without the
Gatekeeper prompt), the next step up is enrolling in the Apple Developer
Program, getting a Developer ID Application certificate, and notarizing the
build with `notarytool` before zipping — none of that is wired up yet.

## Project layout

```
project.yml              XcodeGen project definition (source of truth)
Makefile                 generate / open / build / release / clean
Config/Info.plist        generated by XcodeGen (gitignored)
.github/workflows/
  release.yml            builds and publishes a GitHub Release on tag push
Sources/
  OnAirApp.swift         app entry, Settings scene
  AppDelegate.swift      status item: left-click toggles, right-click menu
  SettingsView.swift     Home Assistant configuration form
  OnAirController.swift  policy: mic + automation + override -> sign state
  MicMonitor.swift       CoreAudio sensor (is any input running)
  HomeAssistant.swift    REST actuator
  KeychainToken.swift    token storage in the login Keychain
```

## License

MIT. See [LICENSE](LICENSE).
