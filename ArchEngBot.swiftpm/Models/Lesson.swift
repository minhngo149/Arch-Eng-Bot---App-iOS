import Foundation

struct Lesson: Decodable, Equatable, Identifiable {
    let id: Int
    let lessonDate: String
    let topic: String
    let model: String
    let createdAt: String?
    let vocab: [Vocab]
    let dialogue: [DialogueMessage]

    enum CodingKeys: String, CodingKey {
        case id, topic, model, vocab, dialogue
        case lessonDate = "lesson_date"
        case createdAt = "created_at"
    }
}

struct Vocab: Decodable, Equatable, Identifiable {
    var id: Int { position }
    let position: Int
    let word: String
    let partOfSpeech: String
    let pronunciationIpa: String
    let meaningEn: String
    let meaningVi: String
    let exampleSentence: String

    enum CodingKeys: String, CodingKey {
        case position, word
        case partOfSpeech = "part_of_speech"
        case pronunciationIpa = "pronunciation_ipa"
        case meaningEn = "meaning_en"
        case meaningVi = "meaning_vi"
        case exampleSentence = "example_sentence"
    }
}

struct DialogueMessage: Decodable, Equatable, Identifiable {
    var id: Int { seq }
    let seq: Int
    let speaker: String
    let speakerRole: String
    let text: String
    let translationVi: String

    enum CodingKeys: String, CodingKey {
        case seq, speaker, text
        case speakerRole = "speaker_role"
        case translationVi = "translation_vi"
    }
}
