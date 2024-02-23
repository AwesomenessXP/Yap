//
//  LocationModel.swift
//  Yap
//
//  Created by Haskell Macaraig on 2/23/24.
//

import SwiftUI
import CoreLocation

class LocationModel: ObservableObject {
    @Published var lat: CLLocationDegrees?
    @Published var long: CLLocationDegrees?
    func storeCoords(lat: CLLocationDegrees, long: CLLocationDegrees) {
        UserDefaults.standard.set(lat, forKey: "latitude")
        UserDefaults.standard.set(long, forKey: "longitude")
    }
    
    func getCoords() -> (CLLocationDegrees, CLLocationDegrees)? {
        if let lat = lat, let long = long {
            return (lat, long)
        }
        return nil
    }
}
