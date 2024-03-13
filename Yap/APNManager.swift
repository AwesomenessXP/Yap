//
//  APNManager.swift
//  Yap
//
//  Created by Haskell Macaraig on 3/2/24.
//

import SwiftUI
import UserNotifications

class APNManager: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, ObservableObject {
    var deviceTokenString: String?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else {
                print("Permission not granted")
                return
            }
            print("Permission granted")
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // convert tok to string, then send to server
        let tok = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        deviceTokenString = tok.joined()
        if let token = deviceTokenString {
            print("Device Token: \(token)")
        }
        
        // send to the server:
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError
                     error: Error) {
        // Try again later.
        print("Failed to register")
        print(error.localizedDescription)
    }
}

extension APNManager {
    static var shared: APNManager? {
        return UIApplication.shared.delegate as? APNManager
    }
}

