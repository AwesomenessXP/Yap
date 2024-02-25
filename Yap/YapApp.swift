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
                .environmentObject(settingsModel)
                .environmentObject(appState)
//                .onAppear() {
//                    websocketClient.connect()
//                    appState.isActive = true
//                }
//                .onChange(of: scenePhase) {
//                    switch scenePhase {
//                    case .active:
//                        Task {
//                            appState.isActive = true
//                            websocketClient.connect()
//                        }
//                    case .background, .inactive:
//                        Task {
//                            appState.isActive = false
//                            websocketClient.connect()
//                        }
//                    @unknown default:
//                        break
//                    }
//                }
        }
    }
}
