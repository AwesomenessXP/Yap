//
//  YapApp.swift
//  Yap
//
//  Created by Haskell Macaraig on 2/9/24.
//

import SwiftUI
import Convex

extension ConvexQueries {
    var listMessages: ConvexQueryDescription {
        ConvexQueryDescription(path: "myFunctions:getMessagesLive")
    }
}

@main
struct YapApp: App {
    @StateObject var locationManager = LocationManager()
    private var client = Client(deploymentUrl: "https://nautical-wolf-360.convex.cloud")

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(locationManager)
                .convexClient(client)
                .task {
                    await client.connect()
                }
        }
    }
}
