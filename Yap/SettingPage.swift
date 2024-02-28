//
//  setting.swift
//  Yap
//
//  Created by Yudi Lai on 2/20/24.
//

import Foundation
import SwiftUI
import Combine

struct SettingPage: View {
    @FocusState var isFocused
    @State var time = ""
    @State var userName: String = ""
    @ObservedObject var settingsModel = SettingsModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack{
            ZStack {
                Form {
                    Section(header: Text("Notification")) {
                        Toggle("Super mode", isOn: .constant(true))
                    }
                    
                    Section(header: Text("User profile")) {
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
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Settings")
                            .font(.headline)
                            .foregroundColor(Color.white)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            time = Date().description(with: .current)
                            settingsModel.updateDate
                            print(time)
                            if settingsModel.addUsername(name: userName) {
                                dismiss()
                            }
                        }) { Text("Save") }
                    }
                }
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
