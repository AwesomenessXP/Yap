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
    @State var timeManager = coolDownTimer()
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
                    //for now just for changing username
                    // check for cool down, if cd good, then apply change
                    // and update new changed time
                    // should the time of last change be stored in server?
                    time = Date().description(with: .current)
                    timeManager.updateDate()
                    
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
//    init(){
//        self.time = Date()
//    }
    func updateDate() -> Void{
        if !self.checkCD(){
            time = Date()
        } else{
            print("within CD")
        }
    }
    func checkCD() -> Bool{
        if let currentTime = time{
            let timeInterval = Date().timeIntervalSince(currentTime)
            print(timeInterval)
            return timeInterval < CD
        }
        else{
            return false
        }
    }
}

#Preview {
    SettingPage()
        .environmentObject(LocationManager())
}
