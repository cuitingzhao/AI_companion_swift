import Foundation
import CoreLocation

public struct LocationResult {
    public let city: String
    public let latitude: Double?
    public let longitude: Double?
}

public enum LocationFetchResult {
    case success(LocationResult)
    case permissionDenied
    case failedToResolve
}

public final class LocationService: NSObject, CLLocationManagerDelegate {
    public static let shared = LocationService()

    private let manager: CLLocationManager
    private var continuation: CheckedContinuation<LocationFetchResult, Never>?

    override public init() {
        self.manager = CLLocationManager()
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    public func fetchCurrentCity() async -> LocationFetchResult {
        guard continuation == nil else {
            return .failedToResolve
        }

        guard CLLocationManager.locationServicesEnabled() else {
            return .permissionDenied
        }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.startLocationFlow()
        }
    }

    private func startLocationFlow() {
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            complete(with: .permissionDenied)
        @unknown default:
            complete(with: .failedToResolve)
        }
    }

    private func complete(with result: LocationFetchResult) {
        guard let continuation = continuation else { return }
        self.continuation = nil
        continuation.resume(returning: result)
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        startLocationFlow()
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            complete(with: .failedToResolve)
            return
        }

        print("📍 Current location: lat=\(location.coordinate.latitude), lon=\(location.coordinate.longitude)")

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }

            if let error = error {
                print("Reverse geocode error: \(error)")
                self.complete(with: .failedToResolve)
                return
            }

            guard let placemark = placemarks?.first else {
                self.complete(with: .failedToResolve)
                return
            }

            let city = placemark.locality
                ?? placemark.administrativeArea
                ?? placemark.subAdministrativeArea
                ?? placemark.name

            guard let city = city, !city.isEmpty else {
                self.complete(with: .failedToResolve)
                return
            }

            let result = LocationResult(
                city: city,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            self.complete(with: .success(result))
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error)")
        complete(with: .failedToResolve)
    }
}
