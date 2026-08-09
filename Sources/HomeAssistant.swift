import Foundation

/// The actuator. A thin wrapper over the Home Assistant REST API that flips a
/// single switch entity on or off.
struct HomeAssistant {
    var baseURL: URL
    var token: String
    var entityID: String

    func setSwitch(on: Bool) async {
        let service = on ? "turn_on" : "turn_off"
        let url = baseURL.appendingPathComponent("api/services/switch/\(service)")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["entity_id": entityID])

        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                NSLog("Home Assistant returned HTTP \(http.statusCode)")
            }
        } catch {
            NSLog("Home Assistant call failed: \(error.localizedDescription)")
        }
    }

    /// Builds a client from saved settings, or nil if not yet configured.
    static func fromDefaults() -> HomeAssistant? {
        let defaults = UserDefaults.standard
        guard
            let urlString = defaults.string(forKey: "haURL"), !urlString.isEmpty,
            let url = URL(string: urlString),
            let entity = defaults.string(forKey: "haEntity"), !entity.isEmpty,
            let token = KeychainToken.load(), !token.isEmpty
        else { return nil }

        return HomeAssistant(baseURL: url, token: token, entityID: entity)
    }
}
