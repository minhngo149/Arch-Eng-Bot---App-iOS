import SwiftUI

/// Small inline button that calls TTS on tap and plays the audio via the
/// shared `AudioPlayer`. Renders three visual states by observing the
/// singleton: idle, loading, and playing.
struct VoicePlayButton: View {
    let text: String
    var size: CGFloat = 16

    private let player = AudioPlayer.shared

    private var isLoading: Bool { player.loadingText == text }
    private var isPlaying: Bool { player.currentlyPlayingText == text }

    var body: some View {
        Button {
            Task { await player.play(text: text) }
        } label: {
            ZStack {
                Circle()
                    .fill(isPlaying ? Color.blue.opacity(0.15) : Color.clear)
                    .frame(width: size + 16, height: size + 16)

                if isLoading {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Image(systemName: isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .font(.system(size: size, weight: .medium))
                        .foregroundStyle(isPlaying ? Color.blue : Color.secondary)
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
    HStack(spacing: 20) {
        VoicePlayButton(text: "seashells")
        VoicePlayButton(text: "office")
    }
    .padding()
}
