import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 40)
                contentView
                    .padding(12)
                    .background(Color.blue, in: BubbleShape(isUser: true))
                    .foregroundStyle(.white)
            }
        case .coach:
            HStack(alignment: .top, spacing: 8) {
                avatar
                contentView
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground),
                                in: BubbleShape(isUser: false))
                Spacer(minLength: 40)
            }
        case .system:
            HStack {
                Spacer()
                contentView
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemGroupedBackground),
                                in: Capsule())
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch message.kind {
        case .text(let value):
            Text(value)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        case .lessonIntro(let lesson):
            LessonIntroCard(lesson: lesson)
        case .vocabList(let vocab):
            VocabListCard(vocab: vocab)
        case .dialogueLine(let line):
            DialogueLineCard(line: line)
        case .voiceTranscript(let result):
            VoiceTranscriptCard(result: result)
        case .error(let message):
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.primary)
            }
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.blue, .indigo],
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
                .frame(width: 28, height: 28)
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

private struct BubbleShape: InsettableShape {
    let isUser: Bool
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 16
        let small: CGFloat = 4
        let inner = rect.insetBy(dx: inset, dy: inset)
        return UnevenRoundedRectangle(
            topLeadingRadius: r,
            bottomLeadingRadius: isUser ? r : small,
            bottomTrailingRadius: isUser ? small : r,
            topTrailingRadius: r,
            style: .continuous
        ).path(in: inner)
    }

    func inset(by amount: CGFloat) -> BubbleShape {
        var copy = self
        copy.inset += amount
        return copy
    }
}

// MARK: - Lesson intro

private struct LessonIntroCard: View {
    let lesson: Lesson

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Lesson · \(lesson.lessonDate)", systemImage: "calendar")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(lesson.topic)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Vocab list

private struct VocabListCard: View {
    let vocab: [Vocab]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Vocabulary (\(vocab.count))", systemImage: "text.book.closed.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(vocab) { item in
                    VocabRow(item: item)
                }
            }
        }
        .frame(maxWidth: 340, alignment: .leading)
    }
}

private struct VocabRow: View {
    let item: Vocab
    @State private var showVi: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(item.word)
                    .font(.subheadline.weight(.semibold))
                Text("·")
                    .foregroundStyle(.secondary)
                Text(item.partOfSpeech)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Text(item.pronunciationIpa)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.blue)
                VoicePlayButton(text: item.word, size: 14)
                ShowViToggle(isOn: $showVi)
            }

            if showVi {
                Text(item.meaningVi)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }

            Text("e.g., \(item.exampleSentence)")
                .font(.caption2)
                .italic()
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .background(Color(.tertiarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: showVi)
    }
}

// MARK: - Dialogue line

private struct DialogueLineCard: View {
    let line: DialogueMessage
    @State private var showVi: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(line.speaker)
                    .font(.caption.weight(.bold))
                Text("(\(line.speakerRole))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                VoicePlayButton(text: line.text, size: 14)
                ShowViToggle(isOn: $showVi)
            }
            Text(line.text)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            if showVi {
                Text(line.translationVi)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showVi)
    }
}

// MARK: - Show VI toggle

private struct ShowViToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 3) {
                Image(systemName: isOn ? "eye.slash.fill" : "eye")
                    .font(.system(size: 11, weight: .semibold))
                Text("VI")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(isOn ? Color.white : Color.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(isOn ? Color.blue : Color.gray.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "Hide Vietnamese translation" : "Show Vietnamese translation")
    }
}

// MARK: - Voice transcript

private struct VoiceTranscriptCard: View {
    let result: TranscriptResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.caption)
                if let matches = result.matchesTarget {
                    Image(systemName: matches ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(matches ? .green : .yellow)
                        .font(.caption)
                }
            }
            Text(result.transcript)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            if let feedback = result.feedback, !feedback.isEmpty {
                Text(feedback)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 12) {
            MessageBubbleView(message: .init(role: .system, kind: .text("Tap 📚 above to load today's lesson, or ✨ to generate a new one.")))
            MessageBubbleView(message: .init(role: .coach, kind: .text("Welcome to today's lesson.")))
            MessageBubbleView(message: .init(role: .user, kind: .text("Hi! I'm ready.")))
            MessageBubbleView(message: .init(role: .user, kind: .voiceTranscript(TranscriptResult(transcript: "She sells seashells.", matchesTarget: true, feedback: "Nice pronunciation!"))))
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
