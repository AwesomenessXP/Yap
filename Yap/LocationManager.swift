import SwiftUI
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    @Published var degrees: Double = 0
    @Published var locations: [CLLocation]?
    @Published var region: CLCircularRegion?
    @Published var newDist: String?
    let radius: CLLocationDistance = 200.0
        
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
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locations = locations
        if let locations = self.locations {
            region = CLCircularRegion(center: locations[locations.count-1].coordinate, radius: radius, identifier: "MyCircularRegion")
            if let region = region {
                print("Circular Region: \(region)")
            }
            if locations.count >= 2 {
                newDist = ("\(locations[locations.count-1].distance(from: locations[locations.count-2]))")
            }
        }
        print("\(locations)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func checkLocationAuthorization() -> CLAuthorizationStatus {
        return manager.authorizationStatus
    }
}
