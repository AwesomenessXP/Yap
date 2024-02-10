import SwiftUI
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    @Published var degrees: Double = 0
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.startUpdatingHeading()
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.requestAlwaysAuthorization()
        print("\(manager.accuracyAuthorization)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        degrees = newHeading.trueHeading
    }
    
    func requestLocation() {
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        print("\(locations)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
