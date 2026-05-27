import SwiftUI

/// Small inline button that calls TTS on tap and plays the audio via the
/// shared `AudioPlayer`. Renders three visual states by observing the
/// singleton: idle, loading, and playing.
///
/// Pass `onDarkBackground: true` when the button is placed on top of a
/// dark fill (e.g. user bubble) so the icon stays legible.
struct VoicePlayButton: View {
    let text: String
    var size: CGFloat = 16
    var onDarkBackground: Bool = false

    private let player = AudioPlayer.shared

    private var isLoading: Bool { player.loadingText == text }
    private var isPlaying: Bool { player.currentlyPlayingText == text }
    private var hasError: Bool { player.failedText == text }

    private var iconColor: Color {
        if isPlaying {
            return onDarkBackground ? .white : .blue
        }
        return onDarkBackground ? .white.opacity(0.75) : .secondary
    }

    private var highlightColor: Color {
        guard isPlaying else { return .clear }
        return onDarkBackground ? .white.opacity(0.22) : .blue.opacity(0.15)
    }

    var body: some View {
        Button {
            Task { await player.play(text: text) }
        } label: {
            ZStack {
                Circle()
                    .fill(highlightColor)
                    .frame(width: size + 16, height: size + 16)

                if isLoading {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(onDarkBackground ? .white : .secondary)
                } else if hasError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: size, weight: .medium))
                        .foregroundStyle(.red)
                        .accessibilityLabel("Audio playback failed")
                } else {
                    Image(systemName: isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .font(.system(size: size, weight: .medium))
                        .foregroundStyle(iconColor)
                        .symbolEffect(.variableColor.iterative.reversing, isActive: isPlaying)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "Stop audio" : "Play audio")
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            VoicePlayButton(text: "seashells")
            VoicePlayButton(text: "office")
        }
        HStack(spacing: 20) {
            VoicePlayButton(text: "blue", onDarkBackground: true)
            VoicePlayButton(text: "moon", onDarkBackground: true)
        }
        .padding()
        .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
    }
    .padding()
}
