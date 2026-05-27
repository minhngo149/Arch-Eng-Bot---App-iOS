import Foundation
import Observation

@Observable
@MainActor
final class ConversationViewModel {
    var messages: [ChatMessage] = []
    var draft: String = ""
    var isLoadingLesson: Bool = false
    var isUploadingAudio: Bool = false
    var errorBanner: String?
    private(set) var currentLesson: Lesson?

    let recorder = AudioRecorder()
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
        appendSystemWelcome()
    }

    // MARK: - Derived

    var isRecording: Bool {
        if case .recording = recorder.state { return true }
        return false
    }

    var canSendText: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isUploadingAudio
    }

    var currentTargetText: String? {
        currentLesson?.dialogue.first?.text
    }

    // MARK: - Lesson

    func loadTodayLesson() async {
        guard !isLoadingLesson else { return }
        isLoadingLesson = true
        errorBanner = nil
        defer { isLoadingLesson = false }

        do {
            let lesson = try await client.fetchTodayLesson()
            await ingestLesson(lesson)
        } catch let error as APIError {
            if case .http(404, _) = error {
                await fallbackToLatest()
            } else {
                errorBanner = error.localizedDescription
            }
        } catch {
            errorBanner = error.localizedDescription
        }
    }

    private func fallbackToLatest() async {
        do {
            let lesson = try await client.fetchLatestLesson()
            await ingestLesson(lesson)
            append(.init(role: .system,
                         kind: .text("Chưa có bài hôm nay — đã dùng bài gần nhất.")))
        } catch {
            errorBanner = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func ingestLesson(_ lesson: Lesson) async {
        currentLesson = lesson
        append(.init(role: .coach, kind: .lessonIntro(lesson)))
        if !lesson.vocab.isEmpty {
            append(.init(role: .coach, kind: .vocabList(lesson.vocab)))
        }
        for line in lesson.dialogue {
            append(.init(role: .coach, kind: .dialogueLine(line)))
        }
        append(.init(role: .system,
                     kind: .text("Hãy phản hồi bằng text hoặc nhấn micro để đọc theo.")))
    }

    // MARK: - User input

    func sendDraft() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        append(.init(role: .user, kind: .text(trimmed)))
        draft = ""
    }

    // MARK: - Voice

    func toggleVoice() async {
        if isRecording {
            guard let url = recorder.stop() else { return }
            await uploadVoice(url: url)
        } else {
            await beginRecording()
        }
    }

    private func beginRecording() async {
        errorBanner = nil
        do {
            try await recorder.start()
            if case .denied = recorder.state {
                errorBanner = "Cần cấp quyền micro trong Cài đặt → ArchEngBot."
            }
        } catch {
            errorBanner = error.localizedDescription
        }
    }

    private func uploadVoice(url: URL) async {
        isUploadingAudio = true
        defer { isUploadingAudio = false }
        do {
            let result = try await client.transcribeAudio(
                audioURL: url,
                targetText: currentTargetText
            )
            append(.init(role: .user, kind: .voiceTranscript(result)))
        } catch {
            let message = (error as? APIError)?.errorDescription ?? error.localizedDescription
            append(.init(role: .system, kind: .error(message)))
        }
    }

    // MARK: - Helpers

    func dismissError() {
        errorBanner = nil
    }

    private func append(_ message: ChatMessage) {
        messages.append(message)
    }

    private func appendSystemWelcome() {
        append(.init(
            role: .system,
            kind: .text("Chào! Nhấn nút 📚 phía trên để lấy bài học hôm nay.")
        ))
    }
}
