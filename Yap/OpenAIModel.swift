//
//  OpenAITypes.swift
//  Yap
//
//  Created by Haskell Macaraig on 3/2/24.
//

import SwiftUI

struct OpenAIRequest: Codable {
    let path: String
    let args: Args
    let format: String
    
    struct Args: Codable {
        let input: String
    }
}

struct OpenAIResponse: Codable {
    let status: String
    let value: Value
}

struct Value: Codable {
    let id: String
    let model: String
    let results: [Result]
}

struct Result: Codable {
    let categories: Categories
    let categoryScores: CategoryScores
    let flagged: Bool

    enum CodingKeys: String, CodingKey {
        case categories
        case categoryScores = "category_scores"
        case flagged
    }
}

struct Categories: Codable {
    let harassment: Bool
    let harassmentThreatening: Bool
    let hate: Bool
    let hateThreatening: Bool
    let selfHarm: Bool
    let selfHarmInstructions: Bool
    let selfHarmIntent: Bool
    let sexual: Bool
    let sexualMinors: Bool
    let violence: Bool
    let violenceGraphic: Bool

    enum CodingKeys: String, CodingKey {
        case harassment
        case harassmentThreatening = "harassment/threatening"
        case hate
        case hateThreatening = "hate/threatening"
        case selfHarm = "self-harm"
        case selfHarmInstructions = "self-harm/instructions"
        case selfHarmIntent = "self-harm/intent"
        case sexual
        case sexualMinors = "sexual/minors"
        case violence
        case violenceGraphic = "violence/graphic"
    }
}

struct CategoryScores: Codable {
    let harassment: Double
    let harassmentThreatening: Double
    let hate: Double
    let hateThreatening: Double
    let selfHarm: Double
    let selfHarmInstructions: Double
    let selfHarmIntent: Double
    let sexual: Double
    let sexualMinors: Double
    let violence: Double
    let violenceGraphic: Double

    enum CodingKeys: String, CodingKey {
        case harassment
        case harassmentThreatening = "harassment/threatening"
        case hate
        case hateThreatening = "hate/threatening"
        case selfHarm = "self-harm"
        case selfHarmInstructions = "self-harm/instructions"
        case selfHarmIntent = "self-harm/intent"
        case sexual
        case sexualMinors = "sexual/minors"
        case violence
        case violenceGraphic = "violence/graphic"
    }
}
