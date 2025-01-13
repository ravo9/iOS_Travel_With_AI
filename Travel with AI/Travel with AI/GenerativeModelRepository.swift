//
//  GenerativeModelRepository.swift
//  Travel with AI
//
//  Created by Rafal Ozog on 13/01/2025.
//

import Foundation
import UIKit

struct ModelNames {
    static let gemini15Flash = "gemini-1.5-flash"
    static let gemini20FlashExp = "gemini-2.0-flash-exp"
}

class GenerativeModelRepository {
    private var apiKey: String
    private var modelName: String
    
    init(apiKey: String, modelName: String = ModelNames.gemini20FlashExp) {
        self.apiKey = apiKey
        self.modelName = modelName
    }
    
    func initializeModel(apiKey: String) {
        self.apiKey = apiKey
        // Optionally perform any setup or validation if needed
    }
    
    func generateResponse(prompt: String) async throws -> String? {
        // Update with the correct Gemini API endpoint
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") // Use your Google API key

        // Construct the payload matching the Gemini API requirements
        let payload: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        // Serialize the payload to JSON
        let jsonPayload = try JSONSerialization.data(withJSONObject: payload, options: [])
        request.httpBody = jsonPayload
        
        // Perform the network request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check the HTTP response status
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            return errorMessage // Probably wrong, my edit.
//            throw NSError(domain: "GenerativeModelError", code: httpResponse?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Decode the response
        let decodedResponse = try JSONDecoder().decode(GoogleGeminiResponse.self, from: data)
        
        // Extract the generated text
        return decodedResponse.contents?.first?.parts?.first?.text
    }
}

struct GoogleGeminiResponse: Decodable {
    struct Content: Decodable {
        struct Part: Decodable {
            let text: String
        }
        let parts: [Part]?
    }
    let contents: [Content]?
}
