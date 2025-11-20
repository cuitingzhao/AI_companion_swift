import Foundation

public enum CalendarAPIError: Error {
    case invalidURL
    case badResponse
}

@MainActor
public final class CalendarAPI {
    public static let shared = CalendarAPI()
    public let baseURL: URL

    public init(baseURL: URL = URL(string: "http://localhost:8000")!) {
        self.baseURL = baseURL
    }

    public func fetchTodayCalendar(tz: String? = nil) async throws -> CalendarInfoResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/utils/calendar/today"

        if let tz {
            components.queryItems = [URLQueryItem(name: "tz", value: tz)]
        }

        guard let url = components.url else {
            throw CalendarAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw CalendarAPIError.badResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(CalendarInfoResponse.self, from: data)
    }
}
