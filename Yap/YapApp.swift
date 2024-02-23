//
//  YapApp.swift
//  Yap
//
//  Created by Haskell Macaraig on 2/9/24.
//

import SwiftUI

@main
struct YapApp: App {
    @StateObject var locationManager = LocationManager()
    @StateObject var locationModel = LocationModel()
    let websocketClient = WebsocketClient()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(locationManager)
                .environmentObject(websocketClient)
                .environmentObject(locationModel)
                .task {
                    websocketClient.connect()
                }
        }
    }
}
