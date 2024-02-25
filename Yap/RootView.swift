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
    @EnvironmentObject var settingsModel: SettingsModel

    @State private var messageText = ""
    @State var currentUser = User(name: "JKT")
    @State var latitude: Double?
    @State var longitude: Double?
    @State var btnDisabled: Bool = true
    @State var username: String = ""
    @State var usernameSet: Bool = false
    
    @FocusState var isFocused: Bool

    var body: some View {
        NavigationStack {
            if self.usernameSet {
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
                        .sensoryFeedback(.impact, trigger: messages.count)
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
                        }
                        catch {
                            print("Unable to fetch location")
                        }
                    }
                }
                .alert("YAP needs to use your location to access your messages", isPresented: .constant(!locationManager.isAuthorized()), actions: {
                    Button("OK", role: .cancel) {}
                })
            }
            else {
                VStack {
                    Text("Enter a username")
                        .font(.system(size: 23)).bold()
                        .foregroundStyle(.white)
                    Group {
                        TextField("Username", text: $username)
                            .bold()
                            .foregroundStyle(.white)
                            .frame(width: 330, height: 50)
                            .multilineTextAlignment(.center)
                            .onChange(of: username) {
                                if !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    self.btnDisabled = false
                                    let _ = settingsModel.addUsername(name: username)
                                }
                                else {
                                    self.btnDisabled = true
                                }
                            }
                            .sensoryFeedback(.increase, trigger: username.count)
                    }
                    .background(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.45), lineWidth: 2))
                    .padding()
                    
                    Button {
                        let _ = self.settingsModel.addUsername(name: username)
                        self.usernameSet = true
                    } label: {
                        Text("Start Yappin")
                    }
                    .frame(width: 330, height: 50)
                    .foregroundStyle(.black).bold()
                    .disabled(self.btnDisabled)
                    .background(.white)
                    .cornerRadius(15)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
        }
        .onAppear {
            let token = UserDefaults.standard.value(forKey: "user_token")
            let hasUser = settingsModel.getUsername()
            
            if (token == nil) {
                usernameSet = false
            } else if (hasUser != nil) {
                usernameSet = true
            }
    
        }
    }
    
    var logoView: some View {
        HStack {
            Text("YAPPIN")
                .font(.system(size: 21)).bold()
                .foregroundColor(.white)
        }
    }

    var headerView: some View {
        ZStack {
            logoView
            HStack {
                Spacer()
                NavigationLink(destination: MapView()) {
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
                        // Limit message text to 240 characters
                        messageText = String(messageText.prefix(240))
                    }
                    .padding(.leading, 15)
                    .sensoryFeedback(.increase, trigger: messageText.count)
            }
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 30).stroke(Color.gray.opacity(0.3), lineWidth: 2))
            
            Button(action: {
                sendMessage(message: messageText)
            }) {
                // Change the button icon based on whether the messageText is empty or not
                Image(systemName: messageText.isEmpty ? "arrow.up.circle" : "arrow.up.circle.fill")
                    .foregroundColor(.white)
            }
            .font(.system(size: 27))
            .padding(.leading, 5)
            // Disable the button if the messageText is empty
            .disabled(messageText.isEmpty)
        }
        .padding()
        .focused($isFocused)
    }

    func startLocationUpdates() async throws {
        for try await update in locationManager.updates {
                print("location updates")
                latitude = Double(update.location?.coordinate.latitude ?? 0.0)
                longitude = Double(update.location?.coordinate.longitude ?? 0.0)

                if let latitude = latitude, let longitude = longitude {
                    UserDefaults.standard.set(latitude, forKey: "latitude")
                    UserDefaults.standard.set(longitude, forKey: "longitude")
                    websocketClient.update(latitude: latitude, longitude: longitude)
                }

            if update.isStationary {
                break
            }
        }
    }
    
    func sendMessage(message: String) {
        messageText = ""
        if let name = settingsModel.getUsername() {
            self.currentUser = User(name: name)
            self.usernameSet = true
        }
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
    @State var true_id = UserDefaults.standard.value(forKey: "true_id") as? String ?? ""
    
    var body: some View {
        if message.user == true_id {
            VStack(alignment: .trailing) {
                Text(Optional(message.display_name.description) ?? "")
                    .font(.caption)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.vertical, -1)
                
                HStack {
                    Spacer()
                    Text(Optional(message.message.description) ?? "")
                        .foregroundColor(Color.white)
                        .font(.system(size: 16))
                        .padding(.bottom, 18)
                }
            }
            .padding(.trailing, 30)
            .padding(.leading, 30)
    

        } else {
            VStack(alignment: .leading) {
                Text(Optional(message.display_name.description) ?? "")
                    .font(.caption)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.vertical, -1)

                HStack {
                    Text(Optional(message.message.description) ?? "")
                        .foregroundColor(Color.white)
                        .font(.system(size: 16))
                        .padding(.bottom, 18)
                    Spacer()
                }
            }
            .padding(.trailing, 30)
            .padding(.leading, 30)
        }
    }
}

// Note: The SettingPage struct needs to be defined elsewhere in your code.

#Preview {
    RootView()
        .environmentObject(LocationManager())
        .environmentObject(WebsocketClient())
        .environmentObject(SettingsModel())
}

