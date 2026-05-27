# ArchEngBot — iOS Client

App native iOS (SwiftUI, iOS 17+) cho hệ thống học tiếng Anh hằng ngày. Giao diện
**chat conversation**: user lấy bài học (vocab + dialogue) hiển thị dưới dạng
tin nhắn từ "Coach", và có thể phản hồi bằng text hoặc voice.

## Tính năng MVP

| Thao tác | Trigger | Behavior |
|---|---|---|
| Lấy bài học hôm nay | Nút **Lấy bài học** ở navbar (top-right) | `GET /admin/lessons/today` → push lesson intro + vocab card + từng dialogue line vào chat |
| Gửi tin nhắn text | Nhập vào ô input → nút mũi tên | Append vào chat (chưa có AI reply — BE chat endpoint TBD) |
| Ghi âm giọng nói | Nút **mic** ở input bar (xuất hiện khi ô text trống) | Record `.m4a` → upload `POST /audio/transcribe` → hiển thị transcript + match result trong chat |

## Stack

- **Ngôn ngữ:** Swift 5.10, async/await, `@Observable` (Observation framework)
- **UI:** SwiftUI, iOS 17+
- **Audio:** `AVAudioRecorder` (output `.m4a`, AAC 44.1 kHz mono),
  `AVAudioApplication.requestRecordPermission`
- **Networking:** `URLSession.data(for:)` async, multipart form-data encoder
- **Project generation:** [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Cấu trúc thư mục

```
arch-eng-bot-app-ios/
├── project.yml                       # XcodeGen config
├── ArchEngBot/
│   ├── App/ArchEngBotApp.swift       # @main → ConversationView
│   ├── Config/AppConfig.swift        # baseURL + secret (đọc từ Info.plist)
│   ├── Models/
│   │   ├── Lesson.swift              # Lesson, Vocab, DialogueMessage (Decodable)
│   │   └── ChatMessage.swift         # ChatMessage + TranscriptResult
│   ├── Services/
│   │   ├── APIClient.swift           # actor: fetchTodayLesson / transcribeAudio
│   │   └── AudioRecorder.swift       # @Observable @MainActor recorder wrapper
│   ├── ViewModels/ConversationViewModel.swift
│   ├── Views/
│   │   ├── ConversationView.swift    # Màn hình chính: scroll messages + input bar
│   │   └── Components/
│   │       ├── MessageBubbleView.swift  # Bubble + LessonIntro/Vocab/Dialogue/Transcript cards
│   │       ├── ChatInputBar.swift       # TextField + mic / send button
│   │       └── WaveformView.swift       # Audio level bars khi recording
│   ├── Preview Content/SampleData.swift # Mock Lesson cho SwiftUI previews
│   └── Resources/
│       ├── Info.plist                   # NSMicrophoneUsageDescription, ATS, API_BASE_URL/SECRET
│       └── Assets.xcassets/
└── .gitignore
```

## Yêu cầu

- macOS có **Xcode 15+** (cài qua App Store)
- **XcodeGen** (`brew install xcodegen`)
- iOS 17+ simulator hoặc thiết bị thật
- Backend [arch-eng-bot-be](../arch-eng-bot-be) chạy tại `http://127.0.0.1:8000`

## Setup

```bash
cd arch-eng-bot-app-ios
brew install xcodegen           # nếu chưa có
xcodegen generate               # tạo ArchEngBot.xcodeproj từ project.yml
open ArchEngBot.xcodeproj
```

Trong Xcode: chọn simulator (iPhone 15+) → bấm **Run** (⌘R).

> Mỗi khi thêm/xóa file Swift, chạy lại `xcodegen generate`.

## Cấu hình base URL + secret

Hai key được inject từ build settings (`project.yml`) qua Info.plist vào
[AppConfig.swift](ArchEngBot/Config/AppConfig.swift):

| Key | Debug | Release |
|---|---|---|
| `API_BASE_URL` | `http://127.0.0.1:8000` | `https://api.example.com` (sửa khi deploy) |
| `API_SECRET`   | `dev-secret-change-me` (đổi cho khớp BE `.env`) | (để trống — phải set trước khi build release) |

> **Secret hiện đang dùng để gọi `/admin/lessons/*` của BE.** Khi BE
> mở public iOS endpoints (task 2), bỏ secret khỏi `APIClient` và `AppConfig`.

## API contract iOS đang gọi

### 1. Lấy bài học hôm nay
```
GET {baseURL}/admin/lessons/today?secret={API_SECRET}
```
Response (decode bằng [`Lesson`](ArchEngBot/Models/Lesson.swift)):
```json
{
  "id": 12,
  "lesson_date": "2026-05-27",
  "topic": "Daily standup at an office",
  "model": "gemini-2.5-flash",
  "created_at": "2026-05-27T06:00:00Z",
  "vocab": [
    { "position": 1, "word": "scoping", "part_of_speech": "noun",
      "pronunciation_ipa": "/ˈskoʊ.pɪŋ/",
      "meaning_en": "...", "meaning_vi": "...", "example_sentence": "..." }
  ],
  "dialogue": [
    { "seq": 1, "speaker": "Alex", "speaker_role": "Tech Lead",
      "text": "Good morning team.", "translation_vi": "..." }
  ]
}
```
Nếu BE trả `404` → app fallback `GET /admin/lessons/latest` và hiện banner
"Chưa có bài hôm nay — đã dùng bài gần nhất.".

### 2. Voice → transcript (BE TBD — task 3)
```
POST {baseURL}/audio/transcribe
Content-Type: multipart/form-data

Part 1 (optional): name="target_text" → text/plain (dialogue line user đang luyện)
Part 2:            name="audio_file"  → audio/mp4, filename "user_voice.m4a"
```
Response (decode bằng [`TranscriptResult`](ArchEngBot/Models/ChatMessage.swift)):
```json
{
  "transcript": "She sells seashells",
  "matches_target": true,
  "feedback": "Phát âm rất chuẩn!"
}
```
> **Lưu ý:** endpoint này hiện **chưa có** trong [arch-eng-bot-be](../arch-eng-bot-be).
> Voice button sẽ ghi âm bình thường nhưng upload sẽ lỗi cho tới khi BE implement.
> Khi BE hoàn thành, không cần đổi gì ở iOS — `APIClient.transcribeAudio` đã sẵn.

## Luồng dữ liệu (chat flow)

1. App khởi động → `ConversationView` show một system message chào.
2. User tap nút 📚 trên navbar → `ConversationViewModel.loadTodayLesson()`
   gọi `APIClient.fetchTodayLesson()`.
3. Lesson về → push 3 nhóm message vào `messages`:
   - `lessonIntro` (date + topic)
   - `vocabList` (tất cả vocab trong 1 bubble)
   - `dialogueLine` × N (mỗi câu hội thoại là 1 bubble riêng)
4. User có thể:
   - **Type** vào input → tap mũi tên → append text bubble
   - **Tap mic** (khi input trống) → `AudioRecorder.start()` → bar waveform hiện
     phía trên input → tap lại stop → upload → transcript bubble
5. `ScrollViewReader` auto-scroll tới bubble cuối khi `messages.count` thay đổi.

## Permissions

Info.plist khai báo:
- `NSMicrophoneUsageDescription` — bắt buộc để dùng micro
- `NSAppTransportSecurity.NSAllowsLocalNetworking` — cho phép HTTP tới localhost
  (production phải HTTPS)

Lần chạy đầu, iOS pop-up xin quyền micro. Nếu user từ chối,
`recorder.state == .denied` → error banner hiển thị hướng dẫn vào Settings.

## TODO

- [ ] BE: mở public iOS endpoints (bỏ secret) — task 2
- [ ] BE: implement `/audio/transcribe` với Gemini STT — task 3
- [ ] iOS: lưu lịch sử chat vào local (SwiftData) qua các session
- [ ] iOS: TTS để phát audio các dialogue line cho user nghe trước khi đọc
- [ ] iOS: playback file `.m4a` user vừa ghi để nghe lại
- [ ] iOS: unit tests cho `APIClient` (mock `URLProtocol`)
- [ ] App icon thật
