import SwiftUI
import CoreLocation
import CoreLocationUI
import MapKit
import PhoneNumberKit
//import UserNotifications

struct User {
    var name: String
}

struct RootView: View {
    // Register the AppDelegate for UIKit life cycle events
    @EnvironmentObject var apnManager: APNManager
    @EnvironmentObject var websocketClient: WebsocketClient
    @EnvironmentObject var settingsModel: SettingsModel
    @EnvironmentObject var label: PhoneNumModel

    @State var messageText = ""
    @State var currentUser = User(name: "JKT")
    @State var latitude: Double?
    @State var longitude: Double?
    @State var username: String = ""
    @State var phoneNum: String = ""
    @State var formattedNum: String = ""
    @State var isLogin: Bool = false
    @State var msgUnsent: Bool = false
    @State var timerInterval: TimeInterval = 10
    @Environment(\.scenePhase) var scenePhase
    @FocusState private var isTextFieldFocused: Bool
    @FocusState var isFocused: Bool
    @State private var deviceToken: String = ""

    var body: some View {
        NavigationView {
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
                SignUpView(isLogin: $isLogin, username: $username, phoneNum: $phoneNum, formattedNum: $formattedNum)
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
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5, height: 5)
                        .padding(.bottom, 5)
                    Text("1 online").font(.system(size: 15))
                        .colorScheme(.light)
                        .foregroundColor(.black).bold()
                } else {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5, height: 5)
                        .padding(.bottom, 5)
                    Text("\(websocketClient.user_count) online").font(.system(size: 15))
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
        latitude = LocationManager.shared.location?.coordinate.latitude
        longitude = LocationManager.shared.location?.coordinate.longitude
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


struct MessageView: View {
    @Binding var message: Message
    @Binding var currentUser: User
    @EnvironmentObject var websocketClient: WebsocketClient
    @State var true_id = UserDefaults.standard.value(forKey: "true_id") as? String ?? ""
    var displayUsername: Bool

    var body: some View {
        VStack(alignment: message.user == true_id ? .trailing : .leading) {
            if displayUsername {
                UserLabelView
            }
            HStack {
                if message.user == true_id {
                    Spacer()
                }
                UserMsgView
                if message.user != true_id {
                    Spacer()
                }
            }
        }
        .padding(message.user == true_id ? .trailing : .leading, 28)
        .padding(message.user != true_id ? .trailing : .leading, 80)
    }
    
    var UserLabelView: some View {
        Text(Optional(message.display_name.description) ?? "")
            .font(.caption)
            .font(.system(size: 14))
            .foregroundColor(.gray)
            .colorScheme(.dark)
            .padding(.vertical, -1)
            .textSelection(.enabled)
    }
    
    var UserMsgView: some View {
        Text(Optional(message.message.description) ?? "")
            .foregroundColor(Color.white)
            .font(.system(size: 16))
            .colorScheme(.dark)
            .padding(.bottom, 18)
            .textSelection(.enabled)
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
                ForEach(Array(zip(messages.indices, messages)), id: \.0) { index, message in
                                    MessageView(message: .constant(message),
                                                currentUser: $currentUser,
                                                displayUsername: shouldDisplayUsername(for: index))
                                }
                .rotationEffect(.degrees(180))
            }
            .rotationEffect(.degrees(180))
            .background(Color.clear)
            .scrollIndicators(.hidden)
            .gesture(DragGesture().onChanged { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            })
            .onAppear {
                previousMessages = messages
            }
        }
    }
    
    private func shouldDisplayUsername(for index: Int) -> Bool {
        if index == 0 {
            return true
        }
        return messages[index].user != messages[index - 1].user
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
                    DispatchQueue.global(qos: .userInteractive).async {
                        configuration.isOn.toggle()
                    }
                }
            
            configuration.label
        }
    }
}

//private func sendNotification(count: Int, first: Message) {
//    
//    let notif = UserDefaults.standard.bool(forKey: "notif")
//
//    if (notif) {
//        
//        let content = UNMutableNotificationContent()
//        if (count == 1) {
//            content.title = "New message sent near you"
//        } else {
//            content.title = "\(count) new messages sent near you"
//        
//        }
//        
//        content.body = "\(first.display_name): \(first.message)"
//        content.sound = .default
//
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
//        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
//
//        UNUserNotificationCenter.current().add(request) { error in
//            if let error = error {
//                print("Error scheduling notification: \(error.localizedDescription)")
//            }
//        }
//    }
//}

#Preview {
    RootView()
        .environmentObject(WebsocketClient())
        .environmentObject(SettingsModel())
        .environmentObject(APNManager())
        .environmentObject(PhoneNumModel())
}

