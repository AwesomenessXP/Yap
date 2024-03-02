//
//  ModerationHandler.swift
//  Yap
//
//  Created by Haskell Macaraig on 3/1/24.
//

import SwiftUI

enum InputQuality {
    case offensive
    case clean
    case unknownQol
}

class OpenAIHandler: ObservableObject {
    
    static let shared = OpenAIHandler()
    private init() {}
    
    public func isOffensive(input: String) async -> Bool? {
        guard let url = URL(string: "https://nautical-wolf-360.convex.cloud/api/action") else { return nil }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let body = makeOpenAIRequest(message: input) else { return nil }
        req.httpBody = body
        let res = await fetchOpenAIRequest(req: req)
        
        return res?.value.results.first?.flagged
    }
    
    private func makeOpenAIRequest(message: String) -> Data? {
        let body = OpenAIRequest(path: "myFunctions:mod", args: .init(input: message), format: "json")
        do {
            return try JSONEncoder().encode(body)
        } catch {
            print("Error encoding JSON: \(error)")
            return nil
        }
    }
    
    private func fetchOpenAIRequest(req: URLRequest) async -> OpenAIResponse? {
        guard let (data, response) = try? await URLSession.shared.data(for: req) else {
            return nil
        }
        guard let httpResponse = response as? HTTPURLResponse,
            let res = processStatusCode(statusCode: httpResponse.statusCode, data: data) else {
            print("Server responded with an error")
            return nil
        }
        return res
    }
    
    private func processStatusCode(statusCode: Int, data: Data?) -> OpenAIResponse? {
        switch statusCode {
        case 200...299:
            if let data = data {
                return try? JSONDecoder().decode(OpenAIResponse.self, from: data)
            }
        case 404:
            print("Not Found: The server can not find the requested resource.")
        default:
            print("Received HTTP \(statusCode)")
        }
        return nil
    }
}

