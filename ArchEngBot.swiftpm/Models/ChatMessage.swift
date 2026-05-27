import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: Role
    let kind: Kind
    let createdAt: Date

    enum Role: Equatable {
        case coach
        case user
        case system
    }

    enum Kind: Equatable {
        case text(String)
        case lessonIntro(Lesson)
        case vocabList([Vocab])
        case dialogueLine(DialogueMessage)
        case voiceTranscript(TranscriptResult)
        case error(String)
    }

    init(id: UUID = UUID(), role: Role, kind: Kind, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.kind = kind
        self.createdAt = createdAt
    }
}

struct TranscriptResult: Decodable, Equatable {
    /// Verbatim transcript in the spoken language (typically English).
    let text: String
    /// Vietnamese translation provided by BE. Optional in case BE omits it.
    let translationVi: String?

    enum CodingKeys: String, CodingKey {
        case text
        case translationVi = "translation_vi"
    }
}
