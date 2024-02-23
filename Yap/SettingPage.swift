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
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack{
            ZStack {
                Form {
                    Section(header: Text("Notification")) {
                        Toggle("Super mode", isOn: .constant(true))
                    }
                    
                    Section(header: Text("User profile")) {
                        TextField("User Name", text: $userName).onTapGesture{
                            isFocused = true
                        }
                        .foregroundColor(.white)
                        .focused($isFocused)
                    }
                }
                .preferredColorScheme(.dark)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Settings")
                            .font(.headline)
                            .foregroundColor(Color.white)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            time = Date().description(with: .current)
                            settingTimer.updateDate()
                            print(time)
                            dismiss()
                        }) { Text("Save") }
                    }
                }
            }
        }
    }
}


#Preview {
    SettingPage()
        .environmentObject(LocationManager())
}
