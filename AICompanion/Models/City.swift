import Foundation

public struct City: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let ascii: String?
    public let country: String?
    public let admin: String?
    public let lat: Double?
    public let lng: Double?
}

public struct CityListResponse: Codable {
    public let cities: [City]
    public let total: Int
}
