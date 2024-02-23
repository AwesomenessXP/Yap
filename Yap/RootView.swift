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

    let currentUser = User(id: 5, name: "Jackie")
    @State var latitude: Double?
    @State var longitude: Double?
    
    @FocusState var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack {
                headerView
                if let messages = websocketClient.messages {
                    ScrollView {
                            ForEach(messages) { message in
                                MessageView(message: message, currentUser: currentUser)
                            }
                            .rotationEffect(.degrees(180))
                    }
                    .rotationEffect(.degrees(180))
                    .background(Color.black.opacity(0.9))
                }
                else {
                    Spacer()
                    ProgressView()
                        .scaleEffect(2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    Spacer()
                }
                inputField
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .onTapGesture {
                isFocused = false
            }
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

    var inputField: some View {
        HStack {
            TextField("Type something", text: $messageText)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .foregroundColor(.white)
                .onChange(of: messageText) {
                    messageText = String(messageText.prefix(240))
                }
            
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
        .focused($isFocused)
    }

    func startLocationUpdates() async throws {
        for try await update in locationManager.updates {
            if let speed = update.location?.speed {
                latitude = Double(update.location?.coordinate.latitude ?? 0.0)
                longitude = Double(update.location?.coordinate.longitude ?? 0.0)

                if let latitude = latitude, let longitude = longitude {
                    if speed > 1.43 {
                        websocketClient.modifyQuerySet(
                            args: ["lat": latitude, "long": longitude]
                        )
                    }
                }
            }
            if update.isStationary {
                break
            }
        }
    }
    
    func sendMessage(message: String) {
        messageText = ""
        if let latitude = latitude, let longitude = longitude {
            if !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                websocketClient.sendMessage(displayName: self.currentUser.name, latitude: latitude, longitude: longitude, message: message, userId: String(self.currentUser.id))
            }
        }
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

