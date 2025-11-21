import Foundation

public enum FortuneAPIError: Error {
    case invalidURL
    case badResponse
}

@MainActor
public final class FortuneAPI {
    public static let shared = FortuneAPI()
    public let baseURL: URL

    public init(baseURL: URL = URL(string: "http://localhost:8000")!) {
        self.baseURL = baseURL
    }

    public func fetchDailyFortune(userId: Int, tz: String? = nil) async throws -> DailyFortuneResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/fortune/daily"

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "user_id", value: String(userId))
        ]
        if let tz {
            queryItems.append(URLQueryItem(name: "tz", value: tz))
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw FortuneAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw FortuneAPIError.badResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(DailyFortuneResponse.self, from: data)
    }
}
