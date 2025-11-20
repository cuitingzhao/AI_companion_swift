import Foundation

public enum ExecutionsAPIError: Error {
    case invalidURL
    case badResponse
}

@MainActor
public final class ExecutionsAPI {
    public static let shared = ExecutionsAPI()
    public let baseURL: URL

    public init(baseURL: URL = URL(string: "http://localhost:8000")!) {
        self.baseURL = baseURL
    }

    public func updateExecution(executionId: Int, request: ExecutionUpdateRequest) async throws -> ExecutionUpdateResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/executions/\(executionId)"

        guard let url = components.url else {
            throw ExecutionsAPIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ExecutionsAPIError.badResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(ExecutionUpdateResponse.self, from: data)
    }
}
