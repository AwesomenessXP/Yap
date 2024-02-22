import SwiftUI
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    let updates = CLLocationUpdate.liveUpdates()
    
    @Published var degrees: Double = 0
    @Published var location: [CLLocation]?
        
    override init() {
        super.init()
        manager.delegate = self
        manager.startUpdatingHeading()
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.requestWhenInUseAuthorization()
        print("\(manager.accuracyAuthorization)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        degrees = newHeading.trueHeading
    }
    
    func requestLocation() {
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations
        print("Locations: \(locations)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func checkLocationAuthorization() -> CLAuthorizationStatus {
        return manager.authorizationStatus
    }
    
    func createGridRegion(centerCoordinate: CLLocationCoordinate2D, spanDegrees: CLLocationDegrees) -> MKCoordinateRegion {
        let region = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: spanDegrees * 111000, longitudinalMeters: spanDegrees * 111000)
        return region
    }
}
