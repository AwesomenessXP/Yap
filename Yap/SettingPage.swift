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
    @State var userName: String = ""
    @State var settingsModel = SettingsModel()
    @State var errorMsg = ""
    @State var updateUserNameCorrectly : Bool = false
    @State var showAlert = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack{
            ZStack {
                Form {
                    Section(header: Text("Notification")) {
                        Toggle("Super mode", isOn: .constant(true))
                    }
                    
                    Section(header: Text("User profile")) {
                        // placeholder name, canremove
                        TextField("awesomenessxp2", text: $userName)
                            .onTapGesture{
                                isFocused = true
                            }
                            .foregroundColor(.white)
                            .focused($isFocused)
                    }
                    
                }
                .preferredColorScheme(.dark)
                .navigationBarTitleDisplayMode(.inline)
                .alert( isPresented: $showAlert){
                    Alert(
                        title: Text("User Name Update Fail"),
                        message: Text("\(errorMsg)."),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Settings")
                            .font(.headline)
                            .foregroundColor(Color.white)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            (updateUserNameCorrectly, errorMsg) = settingsModel.addUsername(name: userName)
                            if updateUserNameCorrectly {
                                dismiss()
                            }
                            else if userName == settingsModel.getUsername() ?? ""{
                                dismiss()
                            }
                            else{
                                self.userName = settingsModel.getUsername() ?? ""
                                showAlert = true
                                
                            }
                        }) { Text("Save") }
                    }
                }
            }
            .onTapGesture {
                isFocused = false
            }
            .onAppear() {
                self.userName = settingsModel.getUsername() ?? ""
            }
            
        }
    }
}


#Preview {
    SettingPage()
        .environmentObject(LocationManager())
        .environmentObject(SettingsModel())
}
