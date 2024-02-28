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

    @State var messageText = ""
    @State var currentUser = User(name: "JKT")
    @State var latitude: Double?
    @State var longitude: Double?
    @State var username: String = ""
    @State var isLogin: Bool = false
    @State var timerInterval: TimeInterval = 1 // seconds
    @Environment(\.scenePhase) var scenePhase
    @FocusState private var isTextFieldFocused: Bool

    @FocusState var isFocused: Bool

    var body: some View {
        NavigationStack {
            if self.isLogin {
                if #available(iOS 17, *) {
                    ChatView.onChange(of: scenePhase) { _, newPhase in
                        switchPhase(phase: newPhase)
                    }
                }
                else {
                    ChatView.onChange(of: scenePhase) { newPhase in
                        switchPhase(phase: newPhase)
                    }
                }
            }
            else {
                SignUpView(usernameSet: $isLogin, username: $username)
            }
        }
        .onAppear {
            verifyToken()
        }
    }
    
    var ChatView: some View {
        VStack {
            HeaderView
            if let messages = websocketClient.messages {
                if #available(iOS 17, *) {
                    MessagesView(messages: .constant(messages), currentUser: $currentUser)
                        .sensoryFeedback(.impact, trigger: messages.count)
                }
                else {
                    MessagesView(messages: .constant(messages), currentUser: $currentUser)
                }
            }
            else {
                CustomProgressView
            }
            InputField
        }
        .background(Color.black.edgesIgnoringSafeArea(.all)).onTapGesture {
            isFocused = false
        }
        .alert("YAP needs to use your location to access your messages", isPresented: .constant(!locationManager.isAuthorized()), actions: {
            Button("OK", role: .cancel) {}
        })
        .onAppear {
            print("IN CHAT VIEW")
            Task {
                await startLocationUpdates()
            }
        }

    }
    
    var LogoView: some View {
        ZStack {
            HStack {
                Spacer()
                Text("YAP")
                    .font(.system(size: 18)).bold()
                    .foregroundColor(.black)
                Spacer()
            }
            HStack(alignment: .bottom) {
                if (websocketClient.user_count <= 1) {
                    Text("1 user").font(.system(size: 15))
                        .foregroundColor(.black).bold()
                } else {
                    Text("\(websocketClient.user_count) users").font(.system(size: 15))
                        .foregroundColor(.black).bold()
                }
                
                Spacer()
            }
        }
    }

    var HeaderView: some View {
        ZStack {
            LogoView
            HStack {
                Spacer()
                NavigationLink(destination: MapView()) {
                    Image(systemName: "map").foregroundColor(Color.black)
                }
                    
                NavigationLink(destination: SettingPage()) {
                    Image(systemName: "gear").foregroundColor(Color.black)
                }
            }
            
        }
        .padding(15)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
        .padding()
    }
    
    var CustomProgressView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(2)
                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
            Spacer()
        }
    }
    
    var InputFieldHelper: some View {
        VStack {
            TextField("Type something", text: $messageText, axis: .vertical)
                .focused($isTextFieldFocused)
                .lineLimit(8)
                .foregroundColor(.white)
                .padding([.leading, .trailing], 15)
                .onTapGesture {
                    isTextFieldFocused = true
                }
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
    }

    var InputField: some View {
        HStack {
            HStack {
                if #available(iOS 17.0, *) {
                    InputFieldHelper.onChange(of: messageText) {
                            messageText = String(messageText.prefix(500))
                        }
                        .sensoryFeedback(.increase, trigger: messageText.count)
                }
                else {
                    InputFieldHelper.onChange(of: messageText) { newValue in
                            if newValue.count > 500 {
                                messageText = String(newValue.prefix(500))
                            }
                        }
                }
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            )
            
            Button(action: { sendMessage(message: messageText) }) {
                Image(systemName: messageText.isEmpty ? "arrow.up.circle" : "arrow.up.circle.fill")
                    .foregroundColor(.white)
            }
            .font(.system(size: 27))
            .padding(.leading, 5)
            .disabled(messageText.isEmpty)
        }
        .padding()
        .focused($isFocused)
    }

    @MainActor
    func startLocationUpdates() async {
        Timer.scheduledTimer(withTimeInterval: self.timerInterval, repeats: true) { timer in
            print("location updates")
            Task { @MainActor in
                latitude = locationManager.location?.coordinate.latitude
                longitude = locationManager.location?.coordinate.longitude
                if let latitude = latitude, let longitude = longitude {
                    let serialQueue = DispatchQueue(label: "coord_serial_queue")
                    serialQueue.sync {
                        UserDefaults.standard.set(latitude, forKey: "latitude")
                        UserDefaults.standard.set(longitude, forKey: "longitude")
                        websocketClient.update(latitude: latitude, longitude: longitude)
                    }
                }
            }
        }
    }
    
    func sendMessage(message: String) {
        messageText = ""
        if let name = settingsModel.getUsername() {
            self.currentUser = User(name: name)
            self.isLogin = true
        }
        if let latitude = latitude, let longitude = longitude {
            print("here")
            if !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                print("sent")
                websocketClient.sendMessage(displayName: self.currentUser.name, latitude: latitude, longitude: longitude, message: message)
            }
        }
    }
    
    func switchPhase(phase: ScenePhase) {
        switch phase {
        case .inactive:
            print("inactive")
        case .active:
            Task {
                websocketClient.connect()
                await startLocationUpdates()
            }
        case .background:
            print("background")
        @unknown default:
            fatalError()
        }
    }
    
    func verifyToken() {
        let token = UserDefaults.standard.value(forKey: "user_token")
        let getUser = settingsModel.getUsername()
        isLogin = (token == nil || getUser == nil) ? false : true
        username = getUser ?? ""
    }
}

struct SignUpView: View {
    @EnvironmentObject var settingsModel: SettingsModel
    @Binding var usernameSet: Bool
    @Binding var username: String
    @State private var btnDisabled: Bool = true
    
    var body: some View {
        VStack {
            Text("Enter a username")
                .font(.system(size: 23)).bold()
                .foregroundStyle(.white)
            Group {
                if #available(iOS 17.0, *) {
                    UsernameField
                        .onChange(of: username) { checkBtnDisabled() }
                }
                else {
                    UsernameField
                        .onChange(of: username, { checkBtnDisabled() })
                }
            }
            .background(RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.45), lineWidth: 2))
            .padding()
            SignUpBtn(usernameSet: $usernameSet, username: $username, btnDisabled: $btnDisabled)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    var UsernameField: some View {
        TextField("Username", text: $username)
            .bold()
            .foregroundStyle(.white)
            .frame(width: 330, height: 50)
            .multilineTextAlignment(.center)
    }
    
    func checkBtnDisabled() {
        if !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.btnDisabled = false
        }
    }
}

struct SignUpBtn: View {
    @EnvironmentObject var settingsModel: SettingsModel
    @Binding var usernameSet: Bool
    @Binding var username: String
    @State private var eulaAccepted = false
    let termsUrl = "https://www.example.com/terms"
    @Binding var btnDisabled: Bool
    @State var error: String = ""
    
    var body: some View {
        VStack() {
            Toggle(isOn: $eulaAccepted) {
                HStack(spacing: 1) {
                    Text("I accept the ")
                        .fontWeight(.regular).foregroundStyle(.white)
                    Link("Terms and Conditions", destination: URL(string: termsUrl)!)
                        .foregroundStyle(.gray).fontWeight(.regular)
                }
            }   .toggleStyle(CheckboxToggleStyle())
                .frame(width: 300, alignment: .leading)
                .padding(.bottom)
        }
        Button(action: {
            settingsModel.userCD.updateDate()
            
            let usernameAdd = self.settingsModel.addUsername(name: username)
            if (usernameAdd.0) {
                self.usernameSet = true
            } else {
                error = usernameAdd.1
            }
            
        }) {
            Text("Start Yappin")
                .fontWeight(.semibold)
                .frame(width: 360, height: 50)
        }
        .frame(width: 330, height: 50)
        .foregroundStyle(.black)
        .bold()
        .disabled(!eulaAccepted || self.usernameSet)
        .background(eulaAccepted ? Color.white : Color.gray.opacity(0.5))
        .cornerRadius(15)
        .alert(error, isPresented: Binding(get: {
            return error.count > 0
        }, set: {_,_ in })) {
                    Button("OK", role: .cancel) { }
                }

    }
}

struct MessageView: View {
    @Binding var message: Message
    @Binding var currentUser: User
    @EnvironmentObject var websocketClient: WebsocketClient
    @State var true_id = UserDefaults.standard.value(forKey: "true_id") as? String ?? ""
    
    var body: some View {
        if message.user == true_id {
            VStack(alignment: .trailing) {
                UserLabelView
                HStack {
                    Spacer()
                    UserMsgView
                }
            }
            .padding(.trailing, 28)
            .padding(.leading, 80)
        } else {
            VStack(alignment: .leading) {
                UserLabelView
                HStack {
                    UserMsgView
                    Spacer()
                }
            }
            .padding(.trailing, 80)
            .padding(.leading, 28)
        }
    }
    
    var UserLabelView: some View {
        Text(Optional(message.display_name.description) ?? "")
            .font(.caption)
            .font(.system(size: 14))
            .foregroundColor(.gray)
            .padding(.vertical, -1)
    }
    
    var UserMsgView: some View {
        Text(Optional(message.message.description) ?? "")
            .foregroundColor(Color.white)
            .font(.system(size: 16))
            .padding(.bottom, 18)
    }
}

struct MessagesView: View {
    @EnvironmentObject var websocketClient: WebsocketClient
    @Binding var messages: [Message]
    @Binding var currentUser: User
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach($messages) { message in
                    MessageView(message: message, currentUser: $currentUser)
                }
                .rotationEffect(.degrees(180))
            }
            .rotationEffect(.degrees(180))
            .background(Color.clear)
            .scrollIndicators(.hidden)
            
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        return HStack {
            configuration.label

            Spacer()

            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(configuration.isOn ? .white : .white)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}
#Preview {
    RootView()
        .environmentObject(LocationManager())
        .environmentObject(WebsocketClient())
        .environmentObject(SettingsModel())
}

