import SwiftUI

@main
struct ArchEngBotApp: App {
    init() {
        Task.detached {
            await NetworkProbe.run()
        }
    }

    var body: some Scene {
        WindowGroup {
            ConversationView()
        }
    }
}

/// Boot-time diagnostic. Pings two public HTTPS hosts so we can tell whether
/// the App Sandbox is blocking outgoing connections entirely, or whether the
/// problem is specific to the Fly.io domain. Logs go to the Playgrounds
/// debug console (Cmd+Shift+Y).
enum NetworkProbe {
    static func run() async {
        await probe(label: "apple.com", urlString: "https://www.apple.com/library/test/success.html")
        await probe(label: "BE health", urlString: "\(AppConfig.baseURL.absoluteString)/health")
    }

    private static func probe(label: String, urlString: String) async {
        guard let url = URL(string: urlString) else {
            print("[Probe] \(label) — bad URL: \(urlString)")
            return
        }
        var req = URLRequest(url: url)
        req.timeoutInterval = 15
        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("[Probe] \(label) → HTTP \(code) (\(url.host ?? "?"))")
        } catch {
            let ns = error as NSError
            print("[Probe] \(label) FAILED: \(ns.localizedDescription) | code=\(ns.code) domain=\(ns.domain)")
        }
    }
}
