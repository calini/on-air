import SwiftUI

struct SettingsView: View {
    @AppStorage("haURL") private var haURL = ""
    @AppStorage("haEntity") private var haEntity = ""
    @State private var token = KeychainToken.load() ?? ""

    var body: some View {
        Form {
            Section("Home Assistant") {
                TextField("Base URL", text: $haURL,
                          prompt: Text("http://homeassistant.local:8123"))
                TextField("Switch entity ID", text: $haEntity,
                          prompt: Text("switch.on_air_sign"))
                SecureField("Long-lived access token", text: $token)
                    .onChange(of: token) { _, newValue in
                        KeychainToken.save(newValue)
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding()
    }
}
