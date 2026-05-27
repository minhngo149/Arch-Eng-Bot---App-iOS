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
    let transcript: String
    let matchesTarget: Bool?
    let feedback: String?

    enum CodingKeys: String, CodingKey {
        case transcript, feedback
        case matchesTarget = "matches_target"
    }
}
