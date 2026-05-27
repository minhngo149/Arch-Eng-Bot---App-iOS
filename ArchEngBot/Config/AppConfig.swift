import Foundation

enum AppConfig {
    static let baseURL: URL = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           let url = URL(string: value),
           !value.isEmpty {
            return url
        }
        return URL(string: "http://127.0.0.1:8000")!
    }()

    /// Shared secret used as `?secret=` query param for admin endpoints
    /// while the BE doesn't have public iOS endpoints yet.
    static let apiSecret: String = {
        let value = Bundle.main.object(forInfoDictionaryKey: "API_SECRET") as? String
        return value ?? ""
    }()
}
