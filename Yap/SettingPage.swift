//
//  setting.swift
//  Yap
//
//  Created by Yudi Lai on 2/20/24.
//

import Foundation
import SwiftUI

struct SettingPage: View {
    @FocusState var isFocused
    @State var time = ""
    @State var userName: String = "You"
    @State var settingTimer = coolDownTimer()
    var body: some View {
        VStack{
            HStack{
                Text("Setting")
                    .font(.title)
                    .foregroundColor(.white)
            }
            Spacer()
            VStack{
                HStack{
                    Spacer()
                    Text("User Name").padding(50)
                        .foregroundColor(.white)
                    TextField("User Name", text: $userName).onTapGesture{
                        isFocused = true
                    }
                    .foregroundColor(.white)
                    .background(Color.gray.opacity(0.15))
                    .focused($isFocused)
                    Spacer()
                }
                Spacer()
                Spacer()
                Button("Confirm"){
                    time = Date().description(with: .current)
                    settingTimer.updateDate()
                    print(time)
                }
                .padding()
                .foregroundColor(.white)
                .background(.gray)
                .cornerRadius(30)
                Spacer()
            }
        }.background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

class coolDownTimer{
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
}

#Preview {
    SettingPage()
        .environmentObject(LocationManager())
}
