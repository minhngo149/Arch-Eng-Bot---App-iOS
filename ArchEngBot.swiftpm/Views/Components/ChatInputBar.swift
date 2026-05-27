import SwiftUI

struct ChatInputBar: View {
    @Binding var draft: String
    let isRecording: Bool
    let canSend: Bool
    let onSend: () -> Void
    let onMicTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: 10) {
                TextField("Type a reply…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .disabled(isRecording)

                trailingButton
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))
        }
    }

    @ViewBuilder
    private var trailingButton: some View {
        if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            MicButton(isRecording: isRecording, action: onMicTap)
        } else {
            SendButton(canSend: canSend, action: onSend)
        }
    }
}

private struct MicButton: View {
    let isRecording: Bool
    let action: () -> Void

    @State private var pulse: Bool = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if isRecording {
                    Circle()
                        .stroke(Color.red.opacity(0.4), lineWidth: 2)
                        .frame(width: 56, height: 56)
                        .scaleEffect(pulse ? 1.3 : 1.0)
                        .opacity(pulse ? 0 : 1)
                        .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false),
                                   value: pulse)
                }
                Circle()
                    .fill(LinearGradient(
                        colors: isRecording ? [.red, .pink] : [.blue, .indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44)
                    .shadow(color: (isRecording ? Color.red : Color.blue).opacity(0.3),
                            radius: 8, y: 3)
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .onAppear { pulse = true }
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
    }
}

private struct SendButton: View {
    let canSend: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(canSend ? Color.blue : Color.gray.opacity(0.4))
                    .frame(width: 44, height: 44)
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
        .accessibilityLabel("Send message")
    }
}

#Preview("Empty") {
    VStack {
        Spacer()
        ChatInputBar(
            draft: .constant(""),
            isRecording: false,
            canSend: false,
            onSend: {},
            onMicTap: {}
        )
    }
}

#Preview("Typing") {
    VStack {
        Spacer()
        ChatInputBar(
            draft: .constant("Hello, this is a draft"),
            isRecording: false,
            canSend: true,
            onSend: {},
            onMicTap: {}
        )
    }
}

#Preview("Recording") {
    VStack {
        Spacer()
        ChatInputBar(
            draft: .constant(""),
            isRecording: true,
            canSend: false,
            onSend: {},
            onMicTap: {}
        )
    }
}
