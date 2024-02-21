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

    private let timerInterval: TimeInterval = 10.0
    @State private var messageText = ""
    @State var messages: [(user: User, message: String)] = [(User(id: 0, name: "Bot"), "Welcome to Chat Bot 2.0!")]

    let currentUser = User(id: 1, name: "You")
    @State var latitude: Double = 0.0
    @State var longitude: Double = 0.0

    // Assuming ConvexQuery initialization needs simplification
    // Placeholder for @ConvexQuery to illustrate without direct dynamic updates
    @ConvexQuery(\.listMessages, args: ["lat": Value(floatLiteral: 0.0), "long": Value(floatLiteral: 0.0)]) private var messages_convex

    var body: some View {
        NavigationStack {
            VStack {
                headerView
                messagesView
                inputField
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        .onAppear {
            startLocationUpdates()
        }
    }

    var headerView: some View {
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
            NavigationLink(destination: SettingPage()) {
                Image(systemName: "gear").foregroundColor(Color.white)
            }
        }
        .padding()
        .background(Color.black)
    }

    var messagesView: some View {
        ScrollView {
            // Assuming this simplification for demonstration
            if case let .array(messages_convex) = messages_convex {
                ForEach(messages_convex, id: \.[dynamicMember: "_id"]) { message in
                    MessageView(message: message, currentUser: currentUser)
                }
                .rotationEffect(.degrees(180))
            }
        }
        .rotationEffect(.degrees(180))
        .background(Color.black.opacity(0.9))
    }

    var inputField: some View {
        HStack {
            TextField("Type something", text: $messageText)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .foregroundColor(.white)

            LocationButton {
                Task {
                    await sendMessage(message: messageText)
                }
                locationManager.requestLocation()
            }
            .labelStyle(.iconOnly)
            .cornerRadius(20)
        }
        .padding()
        .background(Color.black)
    }

    func startLocationUpdates() {
        Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { _ in
            self.updateLocation()
        }
    }

    func updateLocation() {
//        Timer.scheduledTimer(withTimeInterval: self.timerInterval, repeats: true) { timer in
            locationManager.requestLocation()
            latitude = Double(locationManager.locations?.last?.coordinate.latitude ?? 0.0)
            longitude = Double(locationManager.locations?.last?.coordinate.longitude ?? 0.0)
            $messages_convex.updateArgsAndSubscribe(newArgs: ["lat": Value(floatLiteral: latitude), "long": Value(floatLiteral: longitude)], client: client)
            
                print("hi")
//                print(messages_convex)

//        }
    }
    
    struct customString: ExpressibleByStringLiteral {
        let value: String
        
        init(stringLiteral value: String) {
            self.value = value
        }
    }
    
    func fetchMessage(message: String) async -> Value? {
        do {
            // Ensure client is unwrapped safely to avoid try? which can suppress errors.
            if let client = self.client {
                // Execute the mutation and handle errors appropriately.
                return try await client.mutation(path: "myFunctions:sendMessage",
                                          args: [
                                              "display_name": Value(stringLiteral: self.currentUser.name),
                                              "message": Value(stringLiteral: message),
                                              "lat": Value(floatLiteral: self.latitude),
                                              "long": Value(floatLiteral: self.longitude),
                                              "user_id": Value(integerLiteral: self.currentUser.id)
                                          ])
            }
        } catch {
            // Handle or log error appropriately
            print("Error sending message: \(error)")
            return nil
        }
        return nil
    }
    
    func sendMessage(message: String) async {
        let parsed_message = await fetchMessage(message: message)
        if let message = parsed_message {
            let message = "\(message)"
            withAnimation {
                messages.append((user: currentUser, message: message))
                self.messageText = ""
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation {
                        
                    }
                }
            }
        }
    }


    func getBotResponse(message: String) -> String {
        return "Echo: \(message)"
    }
}

struct MessageView: View {
    var message: Value
    var currentUser: User

    var body: some View {
        if message.user_id?.description == currentUser.id.description {
            HStack {
                Spacer()
                Text(message.message?.description ?? "")
                    .padding()
                    .foregroundColor(Color.white)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        } else {
            VStack(alignment: .leading) {
                Text(message.display_name?.description ?? "")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 32)

                HStack {
                    Text(message.message?.description ?? "")
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
    }
}

// Note: The SettingPage struct needs to be defined elsewhere in your code.

#Preview {
    RootView()
        .environmentObject(LocationManager())
}

