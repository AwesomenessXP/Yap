import Foundation
import UIKit

struct Message: Identifiable, Codable {
    let id: String
    let display_name: String
    let message: String
    let user: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case display_name = "display_name_stamp"
        case message
        case user = "user"
    }
    var _id: String { id }

}


class WebsocketClient: NSObject, ObservableObject, URLSessionDelegate, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession
    @Published var messages: [Message]?
    private var latestVersionID = 0
    private var latestQueryID = 0
    private var requestId = 0
    @Published var user_id: String? = UIDevice.current.identifierForVendor?.uuidString
    @Published var user_count = 0
    
    override init() {
        session = URLSession(configuration: .default)
    }
    
    func connect() {
<<<<<<< HEAD
        let url = URL(string: "wss://nautical-wolf-360.convex.cloud/api/1.9.1/sync")
        if let url = url {
            webSocketTask = session.webSocketTask(with: url)
            webSocketTask?.resume()
            
            sendInitialConnection()
            listenForMessages()
            
            let token = UserDefaults.standard.value(forKey: "user_token")
            if (token == nil) {
                register()
            }
            else {
                getMessages()
            }
        }
=======
        DispatchQueue.global(qos: .background).async {

        let url = URL(string: "wss://nautical-wolf-360.convex.cloud/api/1.9.1/sync")!
            self.webSocketTask = self.session.webSocketTask(with: url)
            self.webSocketTask?.resume()
        
            self.sendInitialConnection()
            self.listenForMessages()
        
        let token = UserDefaults.standard.value(forKey: "user_token")
        if (token == nil) {
            self.register()
        }
        else {
            self.getMessages()
        }
        }

        
>>>>>>> 50993ee274b37e0ce87f40743fa712141bfe0d3a
    }
    
    private func sendInitialConnection() {
        DispatchQueue.global(qos: .background).async {
            
            let uuidString = UUID().uuidString
            let connectionData: [String: Any] = [
                "connectionCount": 0,
                "lastCloseReason": "InitialConnect",
                "type": "Connect",
                "sessionId": uuidString
            ]
            
            self.send(json: connectionData)
        }
    }
    
    func getMessages() {
        
        let token = UserDefaults.standard.value(forKey: "user_token")
        if ((token != nil) && (user_id != nil)) {
            if let user_id = user_id {
                if let user_token = token {
                latestVersionID = latestVersionID + 1
                print("Sending Add message \(latestVersionID) and \(latestQueryID)")
                 send(json: [
                    "type": "ModifyQuerySet",
                    "baseVersion": latestVersionID - 1,
                    "newVersion": latestVersionID,
                    "modifications": [
                        [
                            "type": "Add",
                            "queryId": latestQueryID,
                            "udfPath": "myFunctions:getMessagesLive",
                            "args": [
                                [
                                    "token": user_token as? String ?? "",
                                    "vendor_id": String(user_id)
                                ]
                            ]
                        ],
                        [
                            "queryId": latestQueryID + 1,
                            "args": [
                                [
                                    "token": user_token as? String ?? "",
                                    "vendor_id": String(user_id)
                                ]
                                    ],
                            "udfPath": "myFunctions:getUserCount",
                            "type": "Add"
                        ]
                    ]
                ])
            }
        }
            
            latestQueryID = latestQueryID + 2
            
        }
        
    }
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            DispatchQueue.global(qos: .background).async {
                switch result {
                case .failure(let error):
                    print("Error in receiving message: \(error)")
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self?.handleMessage(text: text)
                    case .data(let data):
                        print("Received binary data: \(data)")
                    @unknown default:
                        fatalError()
                    }
                }
                DispatchQueue.main.async {
                    if let self = self {
                        self.listenForMessages()
                    }
                }
            }
        }
    }
    
    private func handleMessage(text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            
            if let modifications = jsonResponse["modifications"] as? [[String: Any]] {
                for modification in modifications {
                    if let type = modification["type"] as? String, type == "QueryUpdated",
                       let value = modification["value"] as? [[String: Any]] {
                        let newData = try JSONSerialization.data(withJSONObject: value)
                        let newMessages = try JSONDecoder().decode([Message].self, from: newData)
                        DispatchQueue.main.async {
                            self.messages = newMessages.reversed()
                        }

                    } else if let value = modification["value"] as? [String: Any], let usersCount = value["users_count"] as? Int {
                        DispatchQueue.main.async {
                            self.user_count = usersCount
                        }

                        print("Users count:", usersCount)
                    }
                }
            }
            
            if let result = jsonResponse["result"] as? [String: String], let trueId = result["true_id"] {
                UserDefaults.standard.setValue(trueId, forKey: "true_id")
            }
            
        } catch {
            print("Error parsing message JSON:", error)
        }
    }

    
    func register() {
        DispatchQueue.global(qos: .background).async {
            
            let token = UUID().uuidString
            let display_name = UserDefaults.standard.value(forKey: "username")
            UserDefaults.standard.set(token, forKey: "user_token")
            if let user_id = self.user_id {
                let messagePayload: [String: Any] = [
                    "type": "Mutation",
                    "requestId": self.requestId,
                    "udfPath": "myFunctions:registerUser",
                    "args": [
                        [
                            "display_name": display_name ?? "",
                            "vendor_id": user_id,
                            "token": token
                        ]
                    ]
                ]
                
                self.send(json: messagePayload)
                self.requestId += 1
            }
            self.getMessages()
        }
    }
    
    func update(latitude: Double, longitude: Double) {
        DispatchQueue.global(qos: .background).async {

        let token = UserDefaults.standard.value(forKey: "user_token")
        let display_name = UserDefaults.standard.value(forKey: "username")
        if let user_id = self.user_id {
            let messagePayload: [String: Any] = [
                "type": "Mutation",
                "requestId": self.requestId,
                "udfPath": "myFunctions:updateUser",
                "args": [
                    [
                        "lat": latitude,
                        "long": longitude,
                        "display_name": display_name ?? "",
                        "vendor_id": user_id,
                        "token": token ?? ""
                    ]
                ]
            ]
        
            self.send(json: messagePayload)
            self.requestId += 1
        }
        }

    }
    
    
    private func send(json: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)
            if let jsonString = jsonString {
                webSocketTask?.send(.string(jsonString)) { error in
                    if let error = error {
                        print("Error in sending message: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            print("Error in serializing JSON: \(error)")
        }
    }
    
    func sendMessage(displayName: String, latitude: Double, longitude: Double, message: String) {
        let token = UserDefaults.standard.value(forKey: "user_token") as? String ?? ""
        // Construct the message payload
        if let user_id = self.user_id {
            let messagePayload: [String: Any] = [
                "type": "Mutation",
                "requestId": requestId,
                "udfPath": "myFunctions:sendMessage",
                "args": [
                    [
                        "message": message,
                        "vendor_id": user_id,
                        "token": token
                    ]
                ]
            ]
            
            // Convert the payload to JSON and send it
             send(json: messagePayload)
            
            // Increment the requestId for the next message
            requestId += 1
        }
    }
}
