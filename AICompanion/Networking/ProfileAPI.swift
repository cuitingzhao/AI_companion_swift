import Foundation

public enum ProfileAPIError: Error {
    case invalidURL
    case badResponse
}

@MainActor
public final class ProfileAPI {
    public static let shared = ProfileAPI()
    public let baseURL: URL

    public init(baseURL: URL = URL(string: "http://localhost:8000")!) {
        self.baseURL = baseURL
    }

    public func updateLocation(_ request: LocationUpdateRequest) async throws -> LocationUpdateResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/profile/location"

        guard let url = components.url else {
            throw ProfileAPIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ProfileAPIError.badResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(LocationUpdateResponse.self, from: data)
    }
}
