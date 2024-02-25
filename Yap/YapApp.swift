//
//  YapApp.swift
//  Yap
//
//  Created by Haskell Macaraig on 2/9/24.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var isActive: Bool = false
}

@main
struct YapApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appState = AppState()
    @StateObject var locationManager = LocationManager()
    @StateObject var settingsModel = SettingsModel()
    let websocketClient = WebsocketClient()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(locationManager)
                .environmentObject(websocketClient)
                .task {
                    websocketClient.connect()
                }
                .environmentObject(settingsModel)
                .environmentObject(appState)
                .onChange(of: scenePhase) {
                    switch scenePhase {
                    case .active:
                        appState.isActive = true
                        websocketClient.connect()
                    case .background, .inactive:
                        appState.isActive = false
                    @unknown default:
                        break
                    }
                }
        }
    }
}
