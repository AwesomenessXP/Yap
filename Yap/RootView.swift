//
//  ContentView.swift
//  Yap
//
//  Created by Haskell Macaraig on 2/9/24.
//

import SwiftUI
import CoreLocation
import CoreLocationUI

struct RootView: View {
    @ObservedObject var locationManager = LocationManager()
    
    var body: some View {
        VStack {
            if let myLocation = locationManager.location {
                Text("Latitude: \(myLocation.coordinate.latitude)")
                Text("Longitude: \(myLocation.coordinate.longitude)")
                Text("Horiz Accuracy: \(myLocation.horizontalAccuracy)")
                Text("Vert Accuracy: \(myLocation.verticalAccuracy)")
                Text("Time: \(myLocation.timestamp)")
                LocationButton {
                    locationManager.requestLocation()
                }
                .labelStyle(.iconOnly)
                .cornerRadius(20)
            } else {
                Text("Get location update")
                LocationButton {
                    locationManager.requestLocation()
                }
                .labelStyle(.iconOnly)
                .cornerRadius(20)
            }
        }
        .onAppear() {
        }
    }
}

#Preview {
    RootView()
}
