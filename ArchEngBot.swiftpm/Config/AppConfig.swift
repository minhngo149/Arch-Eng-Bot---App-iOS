import Foundation

/// App-wide runtime config. Values are loaded from `Resources/Config.json`,
/// which is gitignored. Copy `Config.json.example` to `Config.json` and fill in.
enum AppConfig {
    static let baseURL: URL = {
        if let raw = file.apiBaseURL, let url = URL(string: raw), !raw.isEmpty {
            print("[AppConfig] baseURL = \(url.absoluteString)")
            return url
        }
        print("[AppConfig] api_base_url missing/invalid — falling back to localhost")
        return URL(string: "http://127.0.0.1:8000")!
    }()

    static let apiSecret: String = {
        let value = file.apiSecret ?? ""
        print("[AppConfig] apiSecret \(value.isEmpty ? "EMPTY" : "set (\(value.count) chars)")")
        return value
    }()

    // MARK: - Loading

    private static let file: ConfigFile = {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "json") else {
            print("[AppConfig] Config.json not found in bundle. Falling back to defaults. "
                  + "Copy Resources/Config.json.example → Resources/Config.json and fill in.")
            return ConfigFile(apiBaseURL: nil, apiSecret: nil)
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(ConfigFile.self, from: data)
        } catch {
            print("[AppConfig] Could not decode Config.json: \(error). Using defaults.")
            return ConfigFile(apiBaseURL: nil, apiSecret: nil)
        }
    }()
}

private struct ConfigFile: Decodable {
    let apiBaseURL: String?
    let apiSecret: String?

    enum CodingKeys: String, CodingKey {
        case apiBaseURL = "api_base_url"
        case apiSecret = "api_secret"
    }
}
