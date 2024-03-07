//
//  YapApp.swift
//  Yap
//
//  Created by Haskell Macaraig on 2/9/24.
//

import SwiftUI

@main
struct YapApp: App {
    @UIApplicationDelegateAdaptor(APNManager.self) var apnManager
    @StateObject var settingsModel = SettingsModel()
    @StateObject var phoneNumModel = PhoneNumModel()
    @StateObject var websocketClient = WebsocketClient()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(websocketClient)
                .environmentObject(settingsModel)
                .environmentObject(phoneNumModel)
                .environmentObject(websocketClient)
                .onAppear() {
                    websocketClient.connect()
                }
        }
    }
}
