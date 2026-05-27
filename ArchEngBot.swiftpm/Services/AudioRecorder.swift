import Foundation
import AVFoundation
import Observation

@Observable
@MainActor
final class AudioRecorder: NSObject {
    enum State: Equatable {
        case idle
        case recording
        case stopped(URL)
        case denied
    }

    private(set) var state: State = .idle
    private(set) var levels: [CGFloat] = []
    private(set) var elapsed: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private var startedAt: Date?

    func requestPermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func start() async throws {
        let granted = await requestPermission()
        guard granted else {
            state = .denied
            return
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord,
                                mode: .default,
                                options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true)

        let filename = "user_voice_\(Int(Date().timeIntervalSince1970)).m4a"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.record()

        self.recorder = recorder
        self.startedAt = Date()
        self.levels = []
        self.elapsed = 0
        self.state = .recording

        startMetering()
    }

    @discardableResult
    func stop() -> URL? {
        guard let recorder, recorder.isRecording else { return nil }
        recorder.stop()
        meterTimer?.invalidate()
        meterTimer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        let url = recorder.url
        self.recorder = nil
        self.startedAt = nil
        self.state = .stopped(url)
        return url
    }

    func reset() {
        meterTimer?.invalidate()
        meterTimer = nil
        recorder?.stop()
        recorder = nil
        startedAt = nil
        levels = []
        elapsed = 0
        state = .idle
    }

    private func startMetering() {
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickMeter()
            }
        }
    }

    private func tickMeter() {
        guard let recorder, recorder.isRecording else { return }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let clamped = max(-60, min(0, power))
        let normalized = CGFloat((clamped + 60) / 60)
        levels.append(normalized)
        if levels.count > 48 { levels.removeFirst(levels.count - 48) }
        if let startedAt {
            elapsed = Date().timeIntervalSince(startedAt)
        }
    }
}
