//
//  ContentView.swift
//  Yap
//
//  Created by Haskell Macaraig on 2/9/24.
//

import Convex
import SwiftUI
import CoreLocation
import CoreLocationUI

struct User {
    var id: Int
    var name: String
}

struct RootView: View {
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.convexClient) private var client

    
    private let timerInterval: TimeInterval = 1.0
    
    @State private var messageText = ""
    @State var messages: [(user: User, message: String)] = [(User(id: 0, name: "Bot"), "Welcome to Chat Bot 2.0!")]

    let currentUser = User(id: 1, name: "You")
    @State var latitude: Double = 0.0
    @State var longitude: Double = 0.0
    @ConvexQuery(\.listMessages, args: ["lat": Value(floatLiteral: latitude), "long": Value(floatLiteral: longitude)]) private var messages_convex

    var body: some View {
        NavigationStack{
            VStack {
                HStack {
                    Spacer()
                    Text("Yap")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    
                    Image(systemName: "megaphone")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                    Spacer()
                    NavigationLink {
                        SettingPage()
                                    } label: {
                                        Image(systemName: "gear")
                                            .foregroundColor(Color.white)
                                    }
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
                    
                    LocationButton {
                        sendMessage(message: messageText)
                        locationManager.requestLocation()
                    }
                    .labelStyle(.iconOnly)
                    .cornerRadius(20)
                }
                .padding()
                .background(Color.black)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        .onAppear {
            // Start the timer when the view appears
            Timer.scheduledTimer(withTimeInterval: self.timerInterval, repeats: true) { timer in
                locationManager.requestLocation()
                latitude = Double(locationManager.locations?.last?.coordinate.latitude ?? 0.0)
                longitude = Double(locationManager.locations?.last?.coordinate.longitude ?? 0.0)
            }
        }

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
