import Foundation

// MARK: - Request

public struct OnboardingSubmitRequest: Codable {
    public let nickname: String
    public let birthTime: String
    public let cityId: String
    public let gender: String

    enum CodingKeys: String, CodingKey {
        case nickname
        case birthTime = "birth_time"
        case cityId = "city_id"
        case gender
    }
}

// MARK: - Response

public struct OnboardingSubmitResponse: Codable {
    public let userId: Int
    public let bazi: BaziData?
    public let baziAnalysis: BaziAnalysisResult
    public let personalityTraits: [PersonalityTrait]?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case bazi = "bazi_data"
        case baziAnalysis = "bazi_analysis"
        case personalityTraits = "personality_traits"
    }
}

// MARK: - Feedback Request/Response

public struct TraitFeedback: Codable {
    public let traitId: Int
    public let feedbackFlag: String
    public let comment: String?

    enum CodingKeys: String, CodingKey {
        case traitId = "trait_id"
        case feedbackFlag = "feedback_flag"
        case comment
    }

    public init(traitId: Int, feedbackFlag: String, comment: String? = nil) {
        self.traitId = traitId
        self.feedbackFlag = feedbackFlag
        self.comment = comment
    }
}

public struct OnboardingFeedbackRequest: Codable {
    public let userId: Int
    public let traitFeedbacks: [TraitFeedback]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case traitFeedbacks = "trait_feedbacks"
    }

    public init(userId: Int, traitFeedbacks: [TraitFeedback]) {
        self.userId = userId
        self.traitFeedbacks = traitFeedbacks
    }
}

public struct OnboardingFeedbackResponse: Codable {
    public let status: String
    public let message: String
}

// MARK: - Skip Request/Response

public struct OnboardingSkipRequest: Codable {
    public let userId: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }

    public init(userId: Int) {
        self.userId = userId
    }
}

public struct OnboardingSkipResponse: Codable {
    public let status: String
    public let message: String
}

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
