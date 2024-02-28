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
    @EnvironmentObject var websocketClient: WebsocketClient
    @State var removeMessagesAlert: String = ""
    
    var body: some View {
        NavigationStack{
            ZStack {
                Form {
                    Section(header: Text("Notifications")) {
                        Toggle("Super mode", isOn: .constant(true))
                    }
                    
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
                                     body: "Flagging objectionable content:\n\n")
                        }, label: {
                            Text("Flag objectionable content")
                        })
                        Button(action: {
                            openMail(emailTo: "s@fundsy.io",
                                     subject: "Reporting an issue",
                                     body: "Block this user for me:\n\n")
                        }, label: {
                            Text("Block abusive users")
                        })
                        
                        Button(action: {
                            openMail(emailTo: "s@fundsy.io",
                                     subject: "Reporting an issue",
                                     body: "I would like support with:\n\n")
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
                        Button(action: {
                            time = Date().description(with: .current)
                            if settingsModel.addUsername(name: userName).0 {
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
            .replacingOccurrences(of: "\n", with: "%0D%0A")
            .replacingOccurrences(of: " ", with: "+")
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
        .environmentObject(SettingsModel())
}
