//
//  CoolDownManager.swift
//  Yap
//
//  Created by Yudi Lai on 2/22/24.
//

import Foundation
import UserNotifications

// only run updateDate after run hasCD
class SettingsModel: ObservableObject {
    
    let userCD = CoolDownTimer(coolDownTime: 30.0)
    
    func addUsername(name: String) -> (Bool, String) {
        var errorMessage = ""
        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !userCD.hasCD().0 {
            print("saved!")
            UserDefaults.standard.set(name, forKey: "username")
            userCD.updateDate()
            return (true, errorMessage)
        }
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Username cannot be empty"
        }
        else if userCD.hasCD().0 {
            errorMessage = "Please wait another \(Int(30.0 - userCD.hasCD().1))s to change your username"
        }
        else {
            errorMessage = "Oops, unkown error happened"
        }
        return (false, errorMessage)
    }
    
    func getUsername() -> String? {
        return UserDefaults.standard.string(forKey: "username")
    }
    func getNotif() -> Bool {
        return UserDefaults.standard.bool(forKey: "notif")
    }
    func setNotif(to: Bool) -> Bool? {
        UserDefaults.standard.setValue(to, forKey: "notif")
        return self.getNotif()
    }
}

class CoolDownTimer{
    private var time : Date?
    private var CD = 30.0
    private let dateFormatter = DateFormatter()
    private var withinCD = false
    
    init(coolDownTime: Double){
        getTimeStamp()
        CD = coolDownTime
    }
    
    // update cd timestamp
    func updateDate() -> Void{
        // user only after check hasCD
            time = Date()
        if let unwrapped_time = time {
            let time_str = dateFormatter.string(from: unwrapped_time)
            UserDefaults.standard.setValue(time_str, forKey: "SettingChangeTimeStamp")
        }
    }
    
    func hasCD() -> (Bool, Double) {
        var timeInterval = -1.0
        if let currentTime = time{
            timeInterval = Date().timeIntervalSince(currentTime)
            print(timeInterval)
            return (timeInterval < CD, timeInterval)
        }
        else{
            return (false, timeInterval)
        }
    }
    
    func getTimeStamp() -> Void {
        dateFormatter.dateFormat = "dd MMM yyyy HH:mm:ss Z"
        if let time_str = UserDefaults.standard.string(forKey: "SettingChangeTimeStamp"){
            time = dateFormatter.date(from: time_str)
        }
    }
}
