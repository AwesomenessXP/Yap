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


#Preview {
    SettingPage()
        .environmentObject(LocationManager())
}
