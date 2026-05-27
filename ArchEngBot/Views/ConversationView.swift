import SwiftUI

struct ConversationView: View {
    @State private var viewModel = ConversationViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messageList
                if viewModel.isRecording || viewModel.isUploadingAudio {
                    recordingBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                if let error = viewModel.errorBanner {
                    errorBanner(error)
                }
                ChatInputBar(
                    draft: $viewModel.draft,
                    isRecording: viewModel.isRecording,
                    canSend: viewModel.canSendText,
                    onSend: { viewModel.sendDraft() },
                    onMicTap: { Task { await viewModel.toggleVoice() } }
                )
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("ArchEngBot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.loadTodayLesson() }
                    } label: {
                        if viewModel.isLoadingLesson {
                            ProgressView()
                        } else {
                            Label("Bài hôm nay", systemImage: "books.vertical.fill")
                                .labelStyle(.iconOnly)
                        }
                    }
                    .disabled(viewModel.isLoadingLesson || viewModel.isGeneratingLesson)
                    .accessibilityLabel("Lấy bài học hôm nay")

                    Button {
                        Task { await viewModel.crawlNewLesson() }
                    } label: {
                        if viewModel.isGeneratingLesson {
                            ProgressView()
                        } else {
                            Label("Tạo bài mới", systemImage: "sparkles")
                                .labelStyle(.iconOnly)
                        }
                    }
                    .disabled(viewModel.isLoadingLesson || viewModel.isGeneratingLesson)
                    .accessibilityLabel("Crawl bài học mới")
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85),
                       value: viewModel.isRecording)
            .animation(.easeInOut(duration: 0.2),
                       value: viewModel.isUploadingAudio)
        }
    }

    // MARK: - Messages

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let last = viewModel.messages.last {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Recording bar (waveform + status)

    private var recordingBar: some View {
        HStack(spacing: 12) {
            if viewModel.isUploadingAudio {
                ProgressView()
                Text("Đang nhận diện giọng nói…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                WaveformView(levels: viewModel.recorder.levels,
                             isActive: viewModel.isRecording)
                    .frame(height: 32)
                Text(String(format: "%.1fs", viewModel.recorder.elapsed))
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.thinMaterial)
    }

    // MARK: - Error banner

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.primary)
            Spacer()
            Button {
                viewModel.dismissError()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.12))
    }
}

#Preview {
    ConversationView()
}
