//
//  CoolDownManager.swift
//  Yap
//
//  Created by Yudi Lai on 2/22/24.
//

import Foundation

class SettingsModel: ObservableObject {
    private var time : Date?
    private let CD = 5.0
    private let dateFormatter = DateFormatter()
    
    init(){
        getTimeStamp()
    }
    
    func updateDate() -> Void{
        if !self.hasCD(){
            time = Date()
            if let unwrapped_time = time {
                let time_str = dateFormatter.string(from: unwrapped_time)
                UserDefaults.standard.setValue(time_str, forKey: "SettingChangeTimeStamp")
                UserDefaults.standard.synchronize()
            }
        } else{
            print("within CD")
        }
    }
    
    func hasCD() -> Bool{
        if let currentTime = time{
            let timeInterval = Date().timeIntervalSince(currentTime)
            print(timeInterval)
            return timeInterval < CD
        }
        else{
            return false
        }
    }
    
    func getTimeStamp() -> Void {
        dateFormatter.dateFormat = "dd MMM yyyy HH:mm:ss Z"
        if let time_str = UserDefaults.standard.string(forKey: "SettingChangeTimeStamp"){
            time = dateFormatter.date(from: time_str)
            UserDefaults.standard.synchronize()
        }
    }
    
    func addUsername(name: String) -> Bool {
        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            UserDefaults.standard.set(name, forKey: "username")
            return true
        }
        return false
    }
    
    func getUsername() -> String? {
        return UserDefaults.standard.string(forKey: "username")
    }
}
