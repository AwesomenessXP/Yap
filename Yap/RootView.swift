//
//  ContentView.swift
//  Yap
//
//  Created by Haskell Macaraig on 2/9/24.
//

import SwiftUI
import CoreLocation
import CoreLocationUI

struct User {
    var id: Int
    var name: String
}

struct RootView: View {
    // able to access location with location manager, look at commented
    // code for example
    @EnvironmentObject var locationManager: LocationManager
    private let timerInterval: TimeInterval = 1.0
    
//    var body: some View {
// -------- USE THIS AS AN EXAMPLE TO GET USER LOCATION //////
// ---------------------------------------------------- /////
        
//        VStack {
//            if let myLocation = locationManager.locations {
//                Text("Latitude: \(myLocation[myLocation.count-1].coordinate.latitude)")
//                Text("Longitude: \(myLocation[myLocation.count-1].coordinate.longitude)")
//                Text("Horiz Accuracy: \(myLocation[myLocation.count-1].horizontalAccuracy)")
//                Text("Vert Accuracy: \(myLocation[myLocation.count-1].verticalAccuracy)")
//                Text("Time: \(myLocation[myLocation.count-1].timestamp)")
//                if let dist = locationManager.newDist {
//                    Text("Distance from previous location: \(dist)")
//                }
//            } else {
//                Text("Get location update")
//                LocationButton {
//                    locationManager.requestLocation()
//                }
//                .labelStyle(.iconOnly)
//                .cornerRadius(20)
//            }
//        }
//        .onAppear {
//            // Start the timer when the view appears
//            Timer.scheduledTimer(withTimeInterval: self.timerInterval, repeats: true) { timer in
//                locationManager.requestLocation()
//            }
//        }
//    }
    
    @State private var messageText = ""
    @State var messages: [(user: User, message: String)] = [(User(id: 0, name: "Bot"), "Welcome to Chat Bot 2.0!")]
    let currentUser = User(id: 1, name: "You")
    
    var body: some View {
        VStack {
            HStack {
                Text("Yap")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                
                Image(systemName: "megaphone")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.black)
            
            ScrollView {
                ForEach(messages, id: \.message) { userMessage in
                    if userMessage.user.id == currentUser.id {
                        // User message
                        HStack {
                            Spacer()
                            Text(userMessage.message)
                                .padding()
                                .foregroundColor(Color.white)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(10)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 10)
                        }
                    } else {
                        // Bot message
                        VStack(alignment: .leading) {
                            Text(userMessage.user.name)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 32)
                            
                            HStack {
                                Text(userMessage.message)
                                    .padding()
                                    .foregroundColor(Color.white)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(10)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 10)
                                Spacer()
                            }
                        }
                    }
                }.rotationEffect(.degrees(180))
            }
            .rotationEffect(.degrees(180))
            .background(Color.black.opacity(0.9))
            
            HStack {
                TextField("Type something", text: $messageText)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                
                Button {
                    sendMessage(message: messageText)
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                }
                .font(.system(size: 26))
                .padding(.horizontal, 10)
            }
            .padding()
            .background(Color.black)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    func sendMessage(message: String) {
        withAnimation {
            // Append messages with currentUser, no username prefix for user messages
            messages.append((user: currentUser, message: message))
            self.messageText = ""
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    messages.append((user: User(id: 0, name: "Haskell"), message: getBotResponse(message: message)))
                }
            }
        }
    }
    
    func getBotResponse(message: String) -> String {
        // Simulate bot response logic
        return "Echo: \(message)"
    }
}

#Preview {
    RootView()
        .environmentObject(LocationManager())
}
