import SwiftUI
import CoreLocation
import CoreLocationUI

struct User {
    var id: Int
    var name: String
}

struct RootView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var websocketClient: WebsocketClient

    private let timerInterval: TimeInterval = 1
    @State private var messageText = ""

    let currentUser = User(id: 69, name: "Haskell")
    @State var latitude: Double = 0.0
    @State var longitude: Double = 0.0

    var body: some View {
        NavigationStack {
            VStack {
                Text("hey")
                headerView
                messagesView
                inputField
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .onAppear() {
                Task {
                    do {
                        try await startLocationUpdates()
                    } catch {
                        print("Unable to fetch location")
                    }
                }
            }
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
                ForEach(websocketClient.messages) { message in
                    MessageView(message: message, currentUser: currentUser)
                }
                .rotationEffect(.degrees(180))
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
            
            Button {
                Task {
                    sendMessage(message: messageText)
                }
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

    func startLocationUpdates() async throws {
        for try await update in locationManager.updates {
            if let speed = update.location?.speed {
                latitude = Double(update.location?.coordinate.latitude ?? 0.0)
                longitude = Double(update.location?.coordinate.longitude ?? 0.0)

                if speed > 1.43 {
                    websocketClient.modifyQuerySet(
                        args: ["lat": latitude, "long": longitude]
                    )
                }
            }
            if update.isStationary {
                break
            }
        }
    }
    
    struct customString: ExpressibleByStringLiteral {
        let value: String
        
        init(stringLiteral value: String) {
            self.value = value
        }
    }
    
    func sendMessage(message: String) {
        messageText = ""
        websocketClient.sendMessage(displayName: self.currentUser.name, latitude: self.latitude, longitude: self.longitude, message: message, userId: String(self.currentUser.id))
    }

}

struct MessageView: View {
    var message: Message
    var currentUser: User

    var body: some View {
        if message.userId == currentUser.id.description {
            HStack {
                Spacer()
                Text(Optional(message.message.description) ?? "")
                    .padding()
                    .foregroundColor(Color.white)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }
        } else {
            VStack(alignment: .leading) {
                Text(Optional(message.displayName.description) ?? "")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.leading, 32)

                HStack {
                    Text(Optional(message.message.description) ?? "")
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
        .environmentObject(WebsocketClient())
}

