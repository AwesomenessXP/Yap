import SwiftUI
import CoreLocation
import CoreLocationUI
import MapKit
import UserNotifications

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
    @State var msgUnsent: Bool = false
    @State var timerInterval: TimeInterval = 10
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
        .alert("Your message was unsent because it was offensive", isPresented: $msgUnsent, actions: {
            Button("OK", role: .cancel) { self.msgUnsent = false }
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
                Text("YAPPIN")
                    .font(.system(size: 18)).bold()
                    .colorScheme(.dark)
                    .foregroundColor(.black)
                    .fontWeight(.heavy)
                    .italic()
                Spacer()
            }
            HStack(alignment: .bottom) {
                if (websocketClient.user_count <= 1) {
                    Text("1 user").font(.system(size: 15))
                        .colorScheme(.light)
                        .foregroundColor(.black).bold()
                } else {
                    Text("\(websocketClient.user_count) users").font(.system(size: 15))
                        .colorScheme(.light)
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
                .colorScheme(.dark)
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

    func startLocationUpdates() async {
        getLocation()
        Timer.scheduledTimer(withTimeInterval: self.timerInterval, repeats: true) { timer in
            Task {
                await getLocation()
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
            if !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Task {
                    if let isOffensive = 
                        await OpenAIHandler.shared.isOffensive(input: message) {
                        if !isOffensive {
                            websocketClient.sendMessage(displayName: self.currentUser.name, latitude: latitude, longitude: longitude, message: message)
                            print("this msg is safe")
                        }
                        else {
                            print("Uh oh spaghettio! This message is offensive")
                            self.msgUnsent = true
                        }
                    }
                }
            }
        }
    }
    
    func switchPhase(phase: ScenePhase) {
        switch phase {
        case .inactive:
            timerInterval = 30
        case .active:
            Task {
                timerInterval = 10
                websocketClient.connect()
                await startLocationUpdates()
            }
        case .background:
            timerInterval = 60
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
    
    func getLocation() {
        latitude = locationManager.location?.coordinate.latitude
        longitude = locationManager.location?.coordinate.longitude
        if let latitude = latitude, let longitude = longitude {
            let serialQueue = DispatchQueue(label: "coord_serial_queue")
            serialQueue.async {
                UserDefaults.standard.set(latitude, forKey: "latitude")
                UserDefaults.standard.set(longitude, forKey: "longitude")
                websocketClient.update(latitude: latitude, longitude: longitude)
            }
        }
    }
}

struct SignUpView: View {
    @EnvironmentObject var settingsModel: SettingsModel
    @Binding var usernameSet: Bool
    @Binding var username: String
    @State private var btnDisabled: Bool = true
    
    var body: some View {
        VStack {
            Spacer().frame(height: 75)
            HStack {
                Spacer()
                Text("YAPPIN")
                    .font(.system(size: 36)).bold()
                    .foregroundColor(.white)
                    .italic()
                    .fontWeight(.heavy)
                Spacer()
            }.padding(.bottom,5)
            HStack {
                Spacer()
                Text("Chat with people nearby you")
                    .font(.system(size: 18)).bold()
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                Spacer()
            }
            Spacer().frame(height: 20)
            Group {
                UsernameField
                    .onChange(of: username) { newValue in
                        checkBtnDisabled()
                    }
            }
            .background(RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.45), lineWidth: 2))
            .padding()
            Spacer()
            
            SignUpBtn(isLogin: $usernameSet, username: $username, btnDisabled: $btnDisabled)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    var UsernameField: some View {
        TextField("Choose a username", text: $username)
            .bold()
            .colorScheme(.dark)
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
    @Binding var isLogin: Bool
    @Binding var username: String
    @State private var eulaAccepted = false
    let termsUrl = "https://lighthearted-mandazi-3d73bb.netlify.app/Yappin.pdf"
    @Binding var btnDisabled: Bool
    @State var error: String = ""
    @State var unsentError: String = ""
    
    var body: some View {
        VStack() {
            HStack {
                Spacer()
                Toggle(isOn: $eulaAccepted) {
                    HStack(spacing: 1) {
                        Text("I accept the ")
                            .fontWeight(.regular).foregroundStyle(.white)
                        Link("Terms and Conditions", destination: URL(string: termsUrl)!)
                            .foregroundStyle(.gray).fontWeight(.bold)
                    }
                }
                .toggleStyle(CheckboxToggleStyle())
                .font(.system(size: 12))
                Spacer()
            }
            Text(error)
                .foregroundStyle(.red)
            Text(unsentError)
                .foregroundStyle(.red)
            Spacer()
            Spacer()
        }
        
        GeometryReader { geometry in // grab the screen size
            Button(action: { Task {
                let usernameAdd = await self.settingsModel.addUsername(name: username)
                if (usernameAdd.0 && usernameAdd.2 == .clean) {
                    self.isLogin = true
                } else {
                    error = usernameAdd.1
                    if usernameAdd.2 == .offensive {
                        unsentError = "Please choose an appropriate name next time"
                    }
                }
                
            }}) {
                Text("Start Yappin")
                    .fontWeight(.semibold)
                    .frame(width: 360, height: 50)
            }
            .frame(width: 330, height: 50)
            .foregroundStyle(.black)
            .bold()
            .onChange(of: username, perform: {
                username in
                if !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    error = ""
                    self.btnDisabled = false
                }
                else {
                    self.btnDisabled = true
                }
            })
            .disabled(!self.eulaAccepted && self.btnDisabled)
            .background(self.eulaAccepted && !self.btnDisabled ? Color.white : Color.gray.opacity(0.5))
            .cornerRadius(15)
            .position(x: geometry.size.width / 2, y: geometry.size.height - 50)
            
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
            .colorScheme(.dark)
            .padding(.vertical, -1)
    }
    
    var UserMsgView: some View {
        Text(Optional(message.message.description) ?? "")
            .foregroundColor(Color.white)
            .font(.system(size: 16))
            .colorScheme(.dark)
            .padding(.bottom, 18)
    }
}

struct MessagesView: View {
    @EnvironmentObject var websocketClient: WebsocketClient
    @Binding var messages: [Message]
    @Binding var currentUser: User
    @State private var previousMessages: [Message] = []
    @State private var lastNotificationTime: Date = Date()

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
            .onAppear {
                previousMessages = messages
            }
            .onChange(of: messages) { currentMessages in
                let newMessages = currentMessages.filter { !previousMessages.contains($0) }
                if Date().timeIntervalSince(lastNotificationTime) < 60 {
                    return
                }
                
                if let lastMessage = newMessages.last {
                    if (newMessages.count > 0) {
                        sendNotification(count: newMessages.count, first: lastMessage)
                    }
                }
                previousMessages = currentMessages
            }
            
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        return HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(configuration.isOn ? .white : .white)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}

private func sendNotification(count: Int, first: Message) {
    
    let notif = UserDefaults.standard.bool(forKey: "notif")

    if (notif) {
        
        let content = UNMutableNotificationContent()
        if (count == 1) {
            content.title = "New message sent near you"
        } else {
            content.title = "\(count) new messages sent near you"
        
        }
        
        content.body = "\(first.display_name): \(first.message)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
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

