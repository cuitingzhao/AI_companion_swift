import Foundation

public enum CitiesAPIError: Error {
    case invalidURL
    case badResponse
}

@MainActor
public final class CitiesAPI {
    public static let shared = CitiesAPI()
    public let baseURL: URL

    public init(baseURL: URL = URL(string: "http://localhost:8000")!) {
        self.baseURL = baseURL
    }

    public func searchCities(query: String, limit: Int = 10) async throws -> [City] {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/utils/cities"
        var qItems: [URLQueryItem] = []
        if !query.isEmpty {
            qItems.append(URLQueryItem(name: "q", value: query))
        }
        qItems.append(URLQueryItem(name: "limit", value: String(limit)))
        components.queryItems = qItems

        guard let url = components.url else { throw CitiesAPIError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw CitiesAPIError.badResponse
        }
        let decoded = try JSONDecoder().decode(CityListResponse.self, from: data)
        return decoded.cities
    }
}
