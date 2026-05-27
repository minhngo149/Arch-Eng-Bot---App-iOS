import Foundation

#if DEBUG
extension Lesson {
    static let sample = Lesson(
        id: 1,
        lessonDate: "2026-05-27",
        topic: "Daily standup & technical scoping at an office",
        model: "gemini-2.5-flash",
        createdAt: "2026-05-27T06:00:00Z",
        vocab: [
            Vocab(position: 1, word: "scoping", partOfSpeech: "noun",
                  pronunciationIpa: "/ˈskoʊ.pɪŋ/",
                  meaningEn: "the act of defining the boundaries of work",
                  meaningVi: "việc xác định phạm vi công việc",
                  exampleSentence: "We need a scoping session before sprint planning."),
            Vocab(position: 2, word: "blocker", partOfSpeech: "noun",
                  pronunciationIpa: "/ˈblɑː.kɚ/",
                  meaningEn: "something preventing progress",
                  meaningVi: "vấn đề chặn tiến độ",
                  exampleSentence: "My only blocker is the missing API key."),
        ],
        dialogue: [
            DialogueMessage(seq: 1, speaker: "Alex",
                            speakerRole: "Tech Lead",
                            text: "Good morning team. Let's kick off the standup.",
                            translationVi: "Chào team. Bắt đầu standup nhé."),
            DialogueMessage(seq: 2, speaker: "Mia",
                            speakerRole: "Backend Engineer",
                            text: "I shipped the lesson generator yesterday. Today I'll wire up the iOS endpoint.",
                            translationVi: "Hôm qua mình đẩy lesson generator. Hôm nay sẽ wire endpoint cho iOS."),
        ]
    )
}
#endif
