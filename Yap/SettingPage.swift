//
//  setting.swift
//  Yap
//
//  Created by Yudi Lai on 2/20/24.
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

struct SettingPage: View {
    @FocusState var isFocused
    @State var time = ""
    @State var userName: String = ""
    @ObservedObject var settingsModel = SettingsModel()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var websocketClient: WebsocketClient
    @State var showAlert = false
    @State var errorMsg = ""
    @State var removeMessagesAlert: String = ""
    @State var setNotif = false
    
    var body: some View {
        NavigationStack{
            ZStack {
                Form {
//                    Toggle("Notifications", isOn: Binding(get: {settingsModel.getNotif()}, set: { value in
//                           if value {
//                               checkNotificationAuthorization { accessGranted in
//                                   if !accessGranted {
//                                       self.setNotif = true
//                                   } else {
//                                       let _ = settingsModel.setNotif(to: value)
//                                   }
//                               }
//                           } else {
//                               let _ = settingsModel.setNotif(to: value)
//
//                           }
//                       }))

                    Section(header: Text("Update username")) {
                        TextField("awesomenessxp2", text: $userName)
                            .onTapGesture{
                            isFocused = true
                        }
                        .foregroundColor(.white)
                        .focused($isFocused)
                    }
                    
                    Section(header: Text("Safety & Trust"), footer: Text("There is no tolerance for objectionable content or abusive users. We act on reports within 24 hours by removing certain content and ejecting the user who provided the content. You may email us to report inappropriate activity.")) {
                        Button(action: {
                            openMail(emailTo: "s@fundsy.io",
                                     subject: "Reporting an issue",
                                     body: "Flagging objectionable content:\n\n\n\n\n\n\n\n\n----------\nSession Info: \(String(describing: websocketClient.messages))")
                        }, label: {
                            Text("Flag objectionable content")
                        })
                        Button(action: {
                            openMail(emailTo: "s@fundsy.io",
                                     subject: "Reporting an issue",
                                     body: "Block request:\n\n\n\n\n\n\n\n\n----------\nSession Info: \(String(describing: websocketClient.messages))")
                        }, label: {
                            Text("Block abusive users")
                        })
                        
                        Button(action: {
                            openMail(emailTo: "s@fundsy.io",
                                     subject: "Reporting an issue",
                                     body: "I would like support with:\n\n\n\n\n\n\n\n\n----------\nSession Info: \(String(describing: websocketClient.messages))")
                        }, label: {
                            Text("Email us for support")
                        })
                        
                        if (websocketClient.user_count == -1) {
                            Button(action: {
                                websocketClient.connect()
                            }, label: {
                                Text("Show content again")
                            })
                        } else {
                            Button(action: {
                                websocketClient.disconnect()
                                websocketClient.messages = []
                                removeMessagesAlert = "Content is temporarily hidden. Contact us for support, or restart to continue streaming messages."
                            }, label: {
                                Text("Hide all content").foregroundColor(.red)
                            })
                        }
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
                        Button(action: { Task {
                            time = Date().description(with: .current)
                            let setUserName = await settingsModel.addUsername(name: userName)
                            errorMsg = setUserName.1
                            if setUserName.2 == .offensive {
                                errorMsg = "Please choose an appropriate username next time"
                            }
                            if setUserName.0 {
                                if let latitude = LocationManager.shared.location?.coordinate.latitude, let longitude = LocationManager.shared.location?.coordinate.longitude {
                                    websocketClient.update(latitude: latitude, longitude: longitude)
                                }
                                dismiss()
                            }
                            else if userName == settingsModel.getUsername() ?? "" {
                                dismiss()
                            }
                            else {
                                self.userName = settingsModel.getUsername() ?? ""
                                self.showAlert = true
                            }
                        }}) { Text("Save") }
                            .alert( isPresented: $showAlert){
                                Alert(
                                    title: Text("User Name Update Fail"),
                                    message: Text("\(errorMsg)."),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                    }
                }
            }
            .onAppear() {
                self.userName = settingsModel.getUsername() ?? ""
            }.colorScheme(.dark).alert(isPresented: $setNotif) {
                Alert(
                    title: Text("Enable Notifications"),
                    message: Text("To receive notifications, please enable them in the app settings."),
                    primaryButton: .default(Text("Settings"), action: {
                        // Open the app settings
                        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }),
                    secondaryButton: .cancel()
                )
            }
        }
    }
}


func checkNotificationAuthorization(completion: @escaping (Bool) -> Void) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
        DispatchQueue.main.async {
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                completion(true)
            case .denied, .notDetermined, .ephemeral:
                completion(false)
//            case .notDetermined:
//                self.requestNotificationPermission(completion: completion)
            @unknown default:
                completion(false)
            }
        }
    }
}

func openMail(emailTo:String, subject: String, body: String) {
    if let url = URL(string: "mailto:\(emailTo)?subject=\(subject.fixToBrowserString())&body=\(body.fixToBrowserString())"),
       UIApplication.shared.canOpenURL(url)
    {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

extension String {
    func fixToBrowserString() -> String {
        self.replacingOccurrences(of: ";", with: "%3B")
            .replacingOccurrences(of: "\n", with: "\n")
            .replacingOccurrences(of: " ", with: " ")
            .replacingOccurrences(of: "!", with: "%21")
            .replacingOccurrences(of: "\"", with: "%22")
            .replacingOccurrences(of: "\\", with: "%5C")
            .replacingOccurrences(of: "/", with: "%2F")
            .replacingOccurrences(of: "‘", with: "%91")
            .replacingOccurrences(of: ",", with: "%2C")
    }
}

#Preview {
    SettingPage()
        .environmentObject(LocationManager())
        .environmentObject(WebsocketClient())
        .environmentObject(SettingsModel())
}
