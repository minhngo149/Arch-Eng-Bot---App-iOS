import Foundation
import AVFoundation
import Observation

/// Shared singleton for text-to-speech playback. Each `VoicePlayButton`
/// observes `loadingText` and `currentlyPlayingText` to render its
/// loading/playing state. Only one item can play at a time — starting a
/// new playback stops the previous.
@Observable
@MainActor
final class AudioPlayer: NSObject {
    static let shared = AudioPlayer()

    private(set) var loadingText: String?
    private(set) var currentlyPlayingText: String?

    private var player: AVAudioPlayer?
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
        super.init()
    }

    func play(text: String) async {
        print("[AudioPlayer] tap text=\"\(text.prefix(40))\"")
        // Same text already playing → toggle stop.
        if currentlyPlayingText == text {
            print("[AudioPlayer] already playing same text → stop")
            stop()
            return
        }
        stop()
        loadingText = text
        defer { loadingText = nil }

        do {
            let data = try await client.textToSpeech(text: text)
            print("[AudioPlayer] TTS bytes=\(data.count)")
            try activateSession()
            let p = try AVAudioPlayer(data: data)
            p.delegate = self
            p.prepareToPlay()
            self.player = p
            self.currentlyPlayingText = text
            let ok = p.play()
            print("[AudioPlayer] play() returned \(ok), duration=\(p.duration)s, volume=\(p.volume)")
        } catch {
            let ns = error as NSError
            print("[AudioPlayer] play FAILED: \(ns.localizedDescription) | code=\(ns.code) domain=\(ns.domain)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
        currentlyPlayingText = nil
        deactivateSession()
    }

    // MARK: - Session

    private func activateSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
        print("[AudioPlayer] session category=\(session.category.rawValue) active=\(session.isOtherAudioPlaying ? "other" : "ok")")
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance()
            .setActive(false, options: .notifyOthersOnDeactivation)
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            print("[AudioPlayer] finished successfully=\(flag)")
            self.player = nil
            self.currentlyPlayingText = nil
            self.deactivateSession()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            print("[AudioPlayer] decode error: \(error?.localizedDescription ?? "nil")")
            self.player = nil
            self.currentlyPlayingText = nil
            self.deactivateSession()
        }
    }
}
