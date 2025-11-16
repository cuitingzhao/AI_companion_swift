import Foundation

public enum OnboardingAPIError: Error {
    case invalidURL
    case badResponse
}

@MainActor
public final class OnboardingAPI {
    public static let shared = OnboardingAPI()
    public let baseURL: URL

    public init(baseURL: URL = URL(string: "http://localhost:8000")!) {
        self.baseURL = baseURL
    }

    public func submit(_ request: OnboardingSubmitRequest) async throws -> OnboardingSubmitResponse {
        print("🌐 OnboardingAPI.submit() called")
        
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/onboarding/submit"

        guard let url = components.url else {
            print("❌ Invalid URL")
            throw OnboardingAPIError.invalidURL
        }
        
        print("🌐 Request URL:", url.absoluteString)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        if let bodyData = urlRequest.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("🌐 Request body:", bodyString)
        }
        
        print("🌐 Sending request...")
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        print("🌐 Response received")
        if let http = response as? HTTPURLResponse {
            print("🌐 Status code:", http.statusCode)
        }
        
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            print("❌ Bad response")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Response body:", responseString)
            }
            throw OnboardingAPIError.badResponse
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🌐 Response body:", responseString)
        }

        let decoder = JSONDecoder()
        let decodedResponse = try decoder.decode(OnboardingSubmitResponse.self, from: data)
        print("🌐 Successfully decoded response")
        return decodedResponse
    }

    public func submitFeedback(_ request: OnboardingFeedbackRequest) async throws -> OnboardingFeedbackResponse {
        print("🌐 OnboardingAPI.submitFeedback() called")
        
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/onboarding/feedback"

        guard let url = components.url else {
            print("❌ Invalid URL")
            throw OnboardingAPIError.invalidURL
        }
        
        print("🌐 Request URL:", url.absoluteString)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        if let bodyData = urlRequest.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("🌐 Request body:", bodyString)
        }
        
        print("🌐 Sending request...")
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        print("🌐 Response received")
        if let http = response as? HTTPURLResponse {
            print("🌐 Status code:", http.statusCode)
        }
        
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            print("❌ Bad response")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Response body:", responseString)
            }
            throw OnboardingAPIError.badResponse
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🌐 Response body:", responseString)
        }

        let decoder = JSONDecoder()
        let decodedResponse = try decoder.decode(OnboardingFeedbackResponse.self, from: data)
        print("🌐 Successfully decoded response")
        return decodedResponse
    }

    public func sendKYCMessage(_ request: KYCMessageRequest) async throws -> KYCMessageResponse {
        print("🌐 OnboardingAPI.sendKYCMessage() called")

        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/onboarding/message"

        guard let url = components.url else {
            print("❌ Invalid URL")
            throw OnboardingAPIError.invalidURL
        }

        print("🌐 Request URL:", url.absoluteString)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        if let bodyData = urlRequest.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("🌐 Request body:", bodyString)
        }

        print("🌐 Sending request...")
        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        print("🌐 Response received")
        if let http = response as? HTTPURLResponse {
            print("🌐 Status code:", http.statusCode)
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            print("❌ Bad response")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Response body:", responseString)
            }
            throw OnboardingAPIError.badResponse
        }

        if let responseString = String(data: data, encoding: .utf8) {
            print("🌐 Response body:", responseString)
        }

        let decoder = JSONDecoder()
        let decodedResponse = try decoder.decode(KYCMessageResponse.self, from: data)
        print("🌐 Successfully decoded response")
        return decodedResponse
    }

    public func skip(_ request: OnboardingSkipRequest) async throws -> OnboardingSkipResponse {
        print("🌐 OnboardingAPI.skip() called")
        
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/api/v1/onboarding/skip"

        guard let url = components.url else {
            print("❌ Invalid URL")
            throw OnboardingAPIError.invalidURL
        }
        
        print("🌐 Request URL:", url.absoluteString)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        if let bodyData = urlRequest.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("🌐 Request body:", bodyString)
        }
        
        print("🌐 Sending request...")
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        print("🌐 Response received")
        if let http = response as? HTTPURLResponse {
            print("🌐 Status code:", http.statusCode)
        }
        
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            print("❌ Bad response")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Response body:", responseString)
            }
            throw OnboardingAPIError.badResponse
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🌐 Response body:", responseString)
        }

        let decoder = JSONDecoder()
        let decodedResponse = try decoder.decode(OnboardingSkipResponse.self, from: data)
        print("🌐 Successfully decoded response")
        return decodedResponse
    }
}
