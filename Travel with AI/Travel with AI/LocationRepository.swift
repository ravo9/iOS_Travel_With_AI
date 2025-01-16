import Foundation
import CoreLocation

class LocationRepository: NSObject, CLLocationManagerDelegate {
    
    private var locationManager: CLLocationManager
    private var locationContinuation: CheckedContinuation<CLLocation?, Error>?

    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func getCurrentLocation() async throws -> CLLocation? {
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
    }

    // CLLocationManagerDelegate method - called when a new location is available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        locationContinuation?.resume(returning: locations.last)
        locationContinuation = nil
    }

    // Todo: Throw the printed errors.
    // CLLocationManagerDelegate method - called when an error occurs
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            print("Error Code: \(clError.code.rawValue)")
            switch clError.code {
            case .denied:
                print("User denied location permissions.")
            case .locationUnknown:
                print("Location is currently unknown.")
            default:
                print("Unhandled location error: \(clError.localizedDescription)")
            }
        }
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }

    // For testing only - Returns a fake location
    func getFakeLocation() async -> CLLocation {
        // Edinburgh, Leith
        let edinburghLocation = CLLocation(latitude: 55.9701, longitude: -3.1894)
        
        // Wroclaw, Hiszpanska street
        let wroclawLocation = CLLocation(latitude: 51.1080, longitude: 17.0310)
        
        // Bangkok, SuunCity Condo
        let bangkokLocation = CLLocation(latitude: 13.7367, longitude: 100.5339)
        
        // Return one of the test locations, e.g., Edinburgh
        return edinburghLocation
    }
}
