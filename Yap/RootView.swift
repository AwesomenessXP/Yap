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
    @EnvironmentObject var locationManager: LocationManager
    private let timerInterval: TimeInterval = 1.0
    
    var body: some View {
        VStack {
            if let myLocation = locationManager.locations {
                Text("Latitude: \(myLocation[myLocation.count-1].coordinate.latitude)")
                Text("Longitude: \(myLocation[myLocation.count-1].coordinate.longitude)")
                Text("Horiz Accuracy: \(myLocation[myLocation.count-1].horizontalAccuracy)")
                Text("Vert Accuracy: \(myLocation[myLocation.count-1].verticalAccuracy)")
                Text("Time: \(myLocation[myLocation.count-1].timestamp)")
                if let dist = locationManager.newDist {
                    Text("Distance from previous location: \(dist)")
                }
            } else {
                Text("Get location update")
                LocationButton {
                    locationManager.requestLocation()
                }
                .labelStyle(.iconOnly)
                .cornerRadius(20)
            }
        }
        .onAppear {
            // Start the timer when the view appears
            Timer.scheduledTimer(withTimeInterval: self.timerInterval, repeats: true) { timer in
                locationManager.requestLocation()
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(LocationManager())
}
