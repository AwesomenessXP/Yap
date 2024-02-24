import SwiftUI
import CoreLocation
import CoreLocationUI
import MapKit

struct User {
    var name: String
}

struct RootView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var websocketClient: WebsocketClient
    @EnvironmentObject var locationModel: LocationModel
    @EnvironmentObject var settingsModel: SettingsModel

    private let timerInterval: TimeInterval = 1
    @State private var messageText = ""
    @State var currentUser = User(name: "JKT")
    @State var latitude: Double?
    @State var longitude: Double?
    @State var initUsernameNotSet: Bool = true
    @State var usernameNotSet: Bool = true
    @State var username: String = ""
    
    @FocusState var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack {
                headerView
                if let messages = websocketClient.messages {
                    ScrollView {
                            ForEach(messages) { message in
                                MessageView(message: message, currentUser: currentUser, websocketClient: websocketClient)
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
                self.username = settingsModel.getUsername() ?? ""
                if !username.isEmpty {
                    self.currentUser = User(name: username)
                    self.initUsernameNotSet = false
                }
            }
            .alert("YAP needs to use your location to access your messages", isPresented: .constant(!locationManager.isAuthorized()), actions: {
                Button("OK", role: .cancel) {}
            })
        }
    }

    var headerView: some View {
        ZStack {
            HStack {
                Text("YAP")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)
                
                Image(systemName: "megaphone")
                    .font(.system(size: 21))
                    .foregroundColor(.white)
            }
            
            HStack {
                Spacer()
                NavigationLink(destination: ContentView()) {
                    Image(systemName: "map").foregroundColor(Color.white)
                }
                    
                NavigationLink(destination: SettingPage()) {
                    Image(systemName: "gear").foregroundColor(Color.white)
                }
            }
            
        }
        .padding()
        .background(Color.black)
        
        
    }

    var inputField: some View {
        HStack {
            HStack {
                TextField("Type something", text: $messageText)
                    .foregroundColor(.white)
                    .onChange(of: messageText) {
                        messageText = String(messageText.prefix(240))
                    }
                    .padding(.leading, 15)
                    .alert("Please enter a username to continue", isPresented: $initUsernameNotSet, actions: {
                        TextField("username", text: $username)
                            .onChange(of: username) {
                                if !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    self.usernameNotSet = false
                                    let _ = settingsModel.addUsername(name: username)
                                }
                                else {
                                    self.usernameNotSet = true
                                }
                            }
                        Button("OK") {}
                            .disabled(self.usernameNotSet)
                    })
            }
            .padding(.vertical, 8) // Adjust the vertical padding to fit your design needs
            .background(RoundedRectangle(cornerRadius: 30).stroke(Color.gray.opacity(0.3), lineWidth: 2))
            
            Button {
                Task {
                    sendMessage(message: messageText)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.white)
            }
            .font(.system(size: 27))
            .padding(.leading, 5)
        }
        .padding()
        .focused($isFocused)
    }

    func startLocationUpdates() async throws {
        for try await update in locationManager.updates {
//            if let speed = update.location?.speed {
                latitude = Double(update.location?.coordinate.latitude ?? 0.0)
                longitude = Double(update.location?.coordinate.longitude ?? 0.0)
                locationModel.storeCoords(lat: (update.location?.coordinate.latitude ?? 0.0), long: (update.location?.coordinate.longitude ?? 0.0))

                if let latitude = latitude, let longitude = longitude {
//                    if speed > 1.43 {
                        websocketClient.modifyQuerySet(
                            args: ["lat": latitude, "long": longitude]
                        )
//                    \
                }
//            }
            if update.isStationary {
                break
            }
        }
    }
    
    func sendMessage(message: String) {
        messageText = ""
        if let latitude = latitude, let longitude = longitude {
            if !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                websocketClient.sendMessage(displayName: self.currentUser.name, latitude: latitude, longitude: longitude, message: message)
            }
        }
    }

}

struct MessageView: View {
    var message: Message
    var currentUser: User
    var websocketClient: WebsocketClient
    
    var body: some View {
        if message.userId == websocketClient.user_id {
            HStack {
                Spacer()
                Text(Optional(message.message.description) ?? "")
                    .foregroundColor(Color.white)
                    .padding(.horizontal, 16)
            }
            .padding(.trailing, 21)
            .padding(.vertical, 12)
    

        } else {
            VStack(alignment: .leading) {
                Text(Optional(message.displayName.description) ?? "")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.vertical, 3)

                HStack {
                    Text(Optional(message.message.description) ?? "")
                        .foregroundColor(Color.white)
                    Spacer()
                }
            }
            .padding(.leading, 24)
            .padding(.vertical, 5)
        }
    }
}

// Note: The SettingPage struct needs to be defined elsewhere in your code.

#Preview {
    RootView()
        .environmentObject(LocationManager())
        .environmentObject(WebsocketClient())
        .environmentObject(LocationModel())
}

