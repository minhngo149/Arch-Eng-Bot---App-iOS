import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case http(Int, String?)
    case decoding(Error)
    case io(Error)
    case missingSecret

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Phản hồi không hợp lệ từ máy chủ."
        case .http(let code, let body):
            if let body, !body.isEmpty { return "Lỗi \(code): \(body)" }
            return "Máy chủ trả về lỗi \(code)."
        case .decoding(let err):
            return "Không đọc được phản hồi: \(err.localizedDescription)"
        case .io(let err):
            return err.localizedDescription
        case .missingSecret:
            return "Thiếu API secret. Cấu hình API_SECRET trong build settings."
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let baseURL: URL
    private let secret: String
    private let session: URLSession

    init(baseURL: URL = AppConfig.baseURL,
         secret: String = AppConfig.apiSecret,
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.secret = secret
        self.session = session
    }

    // MARK: - Lesson

    func fetchTodayLesson() async throws -> Lesson {
        try await fetchLesson(path: "/admin/lessons/today")
    }

    func fetchLatestLesson() async throws -> Lesson {
        try await fetchLesson(path: "/admin/lessons/latest")
    }

    private func fetchLesson(path: String) async throws -> Lesson {
        guard !secret.isEmpty else { throw APIError.missingSecret }
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "secret", value: secret)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = 30

        let (data, response) = try await sendRequest(request)
        do {
            return try JSONDecoder().decode(Lesson.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    /// Triggers BE to crawl Gemini for a brand-new lesson (source="manual").
    /// Does not affect the scheduled cron lesson. Returns the freshly created lesson.
    func generateNewLesson() async throws -> Lesson {
        guard !secret.isEmpty else { throw APIError.missingSecret }
        var components = URLComponents(
            url: baseURL.appendingPathComponent("/api/lessons/generate"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "secret", value: secret)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.timeoutInterval = 120  // Gemini generation can be slow

        let (data, _) = try await sendRequest(request)
        let decoder = JSONDecoder()
        // BE may return either the lesson directly or an envelope {created, lesson}.
        if let lesson = try? decoder.decode(Lesson.self, from: data) {
            return lesson
        }
        do {
            return try decoder.decode(GenerateLessonEnvelope.self, from: data).lesson
        } catch {
            throw APIError.decoding(error)
        }
    }

    // MARK: - Voice transcribe (BE endpoint TBD — task 3)

    func transcribeAudio(audioURL: URL, targetText: String?) async throws -> TranscriptResult {
        let url = baseURL.appendingPathComponent("/audio/transcribe")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try makeMultipartBody(
                boundary: boundary,
                targetText: targetText,
                audioURL: audioURL
            )
        } catch {
            throw APIError.io(error)
        }

        let (data, _) = try await sendRequest(request)
        do {
            return try JSONDecoder().decode(TranscriptResult.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    // MARK: - Internal

    private func sendRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.io(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw APIError.http(http.statusCode, body)
        }
        return (data, http)
    }

    private func makeMultipartBody(boundary: String,
                                   targetText: String?,
                                   audioURL: URL) throws -> Data {
        var body = Data()
        let crlf = "\r\n"

        if let targetText, !targetText.isEmpty {
            body.appendString("--\(boundary)\(crlf)")
            body.appendString("Content-Disposition: form-data; name=\"target_text\"\(crlf)\(crlf)")
            body.appendString("\(targetText)\(crlf)")
        }

        body.appendString("--\(boundary)\(crlf)")
        body.appendString("Content-Disposition: form-data; name=\"audio_file\"; filename=\"user_voice.m4a\"\(crlf)")
        body.appendString("Content-Type: audio/mp4\(crlf)\(crlf)")
        body.append(try Data(contentsOf: audioURL))
        body.appendString(crlf)

        body.appendString("--\(boundary)--\(crlf)")
        return body
    }
}

private struct GenerateLessonEnvelope: Decodable {
    let created: Bool?
    let lesson: Lesson
}

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
