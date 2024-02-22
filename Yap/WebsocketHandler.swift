import Foundation

struct Message: Identifiable, Codable {
    let id: String
    let displayName: String
    let message: String
    let userId: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case displayName = "display_name"
        case message
        case userId = "user_id"
    }
    var _id: String { id }

}


class WebsocketClient: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession
    @Published var messages: [Message] = []
    private var latestVersionID = 0
    private var latestQueryID = 0
    private var requestId = 0

    init() {
        session = URLSession(configuration: .default)
    }
    
    func connect() {
        let url = URL(string: "wss://nautical-wolf-360.convex.cloud/api/1.9.1/sync")!
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        sendInitialConnection()
        listenForMessages()
    }
    
    private func sendInitialConnection() {
        let uuidString = UUID().uuidString // Generate a new UUID for sessionId
        let connectionData: [String: Any] = [
            "connectionCount": 0,
            "lastCloseReason": "InitialConnect",
            "type": "Connect",
            "sessionId": uuidString
        ]
        
        send(json: connectionData)
    }
    
    func modifyQuerySet(args: [String : Double]) {
        
        
        if (latestQueryID != 0) {
            latestVersionID = latestVersionID + 1
            print("Sending Remove message \(latestVersionID) and \(latestQueryID)")
            send(json: [
                "type": "ModifyQuerySet",
                "baseVersion": latestVersionID - 1,
                "newVersion": latestVersionID,
                "modifications": [
                    [
                        "type": "Remove",
                        "queryId": latestQueryID
                    ]
                ]
            ])
        }
        latestQueryID = latestQueryID + 1
        
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
                        args
                    ]
                ]
            ]
        ])
        
    }
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
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
                
                self?.listenForMessages()
            }
        }
    }
    
    private func handleMessage(text: String) {
        if let data = text.data(using: .utf8) {
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let modifications = jsonResponse?["modifications"] as? [[String: Any]],
                   let queryUpdated = modifications.first(where: { $0["type"] as? String == "QueryUpdated" }),
                   let value = queryUpdated["value"] as? [[String: Any]] {
                    let newData = try JSONSerialization.data(withJSONObject: value, options: [])
                    let newMessages = try JSONDecoder().decode([Message].self, from: newData)
                    DispatchQueue.main.async {
                        self.messages = newMessages.reversed()
                    }
//                    print(messages)
                }
            } catch {
                print("Error parsing message JSON: \(error)")
            }
        }
    }
    
    private func send(json: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)!
            webSocketTask?.send(.string(jsonString)) { error in
                if let error = error {
                    print("Error in sending message: \(error)")
                }
            }
        } catch {
            print("Error in serializing JSON: \(error)")
        }
    }
    
    func sendMessage(displayName: String, latitude: Double, longitude: Double, message: String, userId: String) {
        // Construct the message payload
        let messagePayload: [String: Any] = [
            "type": "Mutation",
            "requestId": requestId,
            "udfPath": "myFunctions:sendMessage",
            "args": [
                [
                    "display_name": displayName,
                    "lat": latitude,
                    "long": longitude,
                    "message": message,
                    "user_id": userId
                ]
            ]
        ]
        
        // Convert the payload to JSON and send it
        send(json: messagePayload)
        
        // Increment the requestId for the next message
        requestId += 1
    }

    
}
