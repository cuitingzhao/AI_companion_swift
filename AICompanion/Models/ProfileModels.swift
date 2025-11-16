import Foundation

public struct LocationUpdateRequest: Codable {
    public let userId: Int
    public let city: String
    public let latitude: Double?
    public let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case city
        case latitude
        case longitude
    }

    public init(userId: Int, city: String, latitude: Double?, longitude: Double?) {
        self.userId = userId
        self.city = city
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct LocationUpdateResponse: Codable {
    public let status: String
    public let message: String
    public let city: String
}
