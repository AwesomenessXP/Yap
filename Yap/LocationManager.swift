import SwiftUI
import CoreLocation
import MapKit

let manager = CLLocationManager()
class LocationManager: NSObject, ObservableObject, Observable, CLLocationManagerDelegate {
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func isAuthorized() -> Bool {
        let status = manager.authorizationStatus
        if status == .denied || status == .restricted || status == .notDetermined {
            return false
        }
        return true
    }
}
