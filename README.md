# ArchEngBot — iOS Client (Swift Playgrounds)

App native iOS (SwiftUI, iOS 17+) cho hệ thống học tiếng Anh hằng ngày.
**Project được đóng gói dạng `.swiftpm` (Swift Playgrounds App Project)** — mở
được bằng **Swift Playgrounds 4+** trên Mac (~1.4 GB từ App Store) hoặc bằng
**Xcode 15+**. Không cần XcodeGen.

Giao diện **chat conversation**: user lấy bài học (vocab + dialogue) hiển thị
dưới dạng tin nhắn từ "Coach", và có thể phản hồi bằng text hoặc voice.

## Tính năng MVP

| Thao tác | Trigger | Behavior |
|---|---|---|
| Lấy bài học hôm nay | Nút 📚 (`books.vertical.fill`) ở navbar | `GET /admin/lessons/today` → push lesson intro + vocab card + từng dialogue line vào chat |
| Crawl bài học mới | Nút ✨ (`sparkles`) ở navbar | `POST /api/lessons/generate` — yêu cầu BE crawl Gemini sinh bài mới (source="manual") |
| Gửi tin nhắn text | Nhập vào ô input → nút mũi tên | Append vào chat (chưa có AI reply — BE chat endpoint TBD) |
| Ghi âm giọng nói | Nút **mic** ở input bar (xuất hiện khi ô text trống) | Record `.m4a` → upload `POST /audio/transcribe` (BE TBD) → transcript bubble |

## Stack

- **Ngôn ngữ:** Swift 5.9+, async/await, `@Observable`
- **UI:** SwiftUI, iOS 17+
- **Audio:** `AVAudioRecorder` (output `.m4a`, AAC 44.1 kHz mono)
- **Networking:** `URLSession.data(for:)` async, multipart form-data
- **Package format:** Swift Playgrounds App Project (`.swiftpm` + `AppleProductTypes.iOSApplication`)

## Cấu trúc

```
arch-eng-bot-app-ios/
├── ArchEngBot.swiftpm/                # ← Mở folder này trong Swift Playgrounds
│   ├── Package.swift                  # iOSApplication declaration (icon, accent, mic capability)
│   ├── App/ArchEngBotApp.swift        # @main → ConversationView
│   ├── Config/AppConfig.swift         # baseURL + secret (đọc từ Resources/Config.json)
│   ├── Models/
│   │   ├── Lesson.swift               # Lesson, Vocab, DialogueMessage
│   │   └── ChatMessage.swift          # ChatMessage + TranscriptResult
│   ├── Services/
│   │   ├── APIClient.swift            # actor: fetchTodayLesson / generateNewLesson / transcribeAudio
│   │   └── AudioRecorder.swift        # @Observable @MainActor recorder wrapper
│   ├── ViewModels/ConversationViewModel.swift
│   ├── Views/
│   │   ├── ConversationView.swift     # Màn hình chính
│   │   └── Components/                # MessageBubble, ChatInputBar, Waveform
│   ├── Previews/SampleData.swift      # Mock Lesson cho SwiftUI Preview
│   └── Resources/
│       ├── Config.json.example        # Template (commit)
│       └── Config.json                # Local secrets (gitignored)
├── README.md
└── .gitignore
```

## Setup nhanh (3 bước)

### 1. Cài Swift Playgrounds

```bash
open "macappstore://apps.apple.com/us/app/swift-playgrounds/id1496833156"
```
Tải ~1.4 GB. Nhanh hơn Xcode rất nhiều.

### 2. Tạo Config.json từ template

```bash
cd /Users/mido/ArchEngBot/arch-eng-bot-app-ios
cp ArchEngBot.swiftpm/Resources/Config.json.example \
   ArchEngBot.swiftpm/Resources/Config.json
```

Edit `Config.json` và paste secret production vào:
```json
{
  "api_base_url": "https://arch-eng-bot---be.fly.dev",
  "api_secret": "<dán secret của BE Fly.io vào đây>"
}
```

> `Config.json` đã được gitignore. `Config.json.example` thì commit để
> người khác clone về có template.

### 3. Mở Swift Playgrounds

```bash
open -a "Swift Playgrounds" ArchEngBot.swiftpm
```

Hoặc trong Swift Playgrounds: **File → Open** → chọn folder `ArchEngBot.swiftpm`.

## Cách preview & chạy

### SwiftUI Preview (live canvas)

1. Click vào file `.swift` có `#Preview { ... }` (ví dụ
   `Views/ConversationView.swift`, `Views/Components/MessageBubbleView.swift`,
   `Views/Components/ChatInputBar.swift`).
2. Preview canvas tự bật bên phải.
3. Edit code → canvas hot-reload tức thì.

### Chạy app

- Bấm nút **▶ Run My App** trên top-right của Playgrounds.
- App chạy thẳng như Mac app (Mac Catalyst-style wrapper).
- Lần đầu sẽ pop-up xin quyền micro — Allow.

> **Lưu ý:** Swift Playgrounds chạy app trên Mac, **không** trên iOS Simulator.
> Muốn test trên iPhone Simulator hay thiết bị thật → vẫn cần Xcode.

## Cũng mở được trong Xcode

Folder `ArchEngBot.swiftpm` là Swift Package hợp lệ. Xcode 15+ mở trực tiếp:
```bash
open -a Xcode ArchEngBot.swiftpm
```
Tất cả Preview và run flow tương tự.

## API contract iOS đang gọi

Production BE: `https://arch-eng-bot---be.fly.dev`
([health check](https://arch-eng-bot---be.fly.dev/health)).

### 1. Lấy bài học hôm nay
```
GET {baseURL}/admin/lessons/today?secret={api_secret}
```
Fallback `GET /admin/lessons/latest` khi 404.

### 2. Crawl bài học mới
```
POST {baseURL}/api/lessons/generate?secret={api_secret}
```
BE gọi Gemini sinh bài mới (source="manual"), có thể mất 30–60s. Client timeout 120s.

### 3. Voice → transcript (BE TBD)
```
POST {baseURL}/audio/transcribe
multipart/form-data: target_text (optional), audio_file (audio/mp4)
```
BE chưa implement — voice button sẽ record OK nhưng upload fail.

## Permissions

- **Microphone** — khai báo qua
  `.microphone(purposeString:)` trong `Package.swift > iOSApplication.capabilities`.
- **App Transport Security** — production HTTPS nên không cần khai báo
  ngoại lệ. Muốn dùng local BE `http://127.0.0.1:8000` thì cần thêm
  ATS exception, mà Swift Playgrounds App Project hiện không cho phép
  override Info.plist ATS keys — hạn chế của format này.

## TODO

- [ ] BE: implement `POST /audio/transcribe` với Gemini STT
- [ ] iOS: persistence lịch sử chat (SwiftData)
- [ ] iOS: TTS phát audio dialogue line
- [ ] iOS: playback file `.m4a` user đã ghi
- [ ] iOS: unit tests cho `APIClient` (mock `URLProtocol`)
- [ ] App icon thật
