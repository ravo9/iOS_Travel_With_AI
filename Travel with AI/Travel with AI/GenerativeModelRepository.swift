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
    private var apiKey: String = ""

    func initializeModel(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateResponse(prompt: String, imageData: Data?) async throws -> String? {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var parts: [[String: Any]] = [["text": prompt]]

        if let imageData = imageData {
            let base64Image = imageData.base64EncodedString()
            parts.append([
                "inlineData": [
                    "mimeType": "image/png",
                    "data": base64Image
                ]
            ])
        }

        let payload: [String: Any] = [
            "contents": [
                ["parts": parts]
            ]
        ]

        let jsonPayload = try JSONSerialization.data(withJSONObject: payload, options: [])
        request.httpBody = jsonPayload

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            return errorMessage // Probably wrong, my edit.
    //        throw NSError(domain: "GenerativeModelError", code: httpResponse?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        let decodedResponse = try JSONDecoder().decode(GoogleGeminiResponse.self, from: data)
        return decodedResponse.candidates?.first?.content?.parts?.first?.text
    }
}

struct GoogleGeminiResponse: Codable {
    let candidates: [Candidate]?
}

struct Candidate: Codable {
    let content: Content?
}

struct Content: Codable {
    let parts: [Part]?
}

struct Part: Codable {
    let text: String
}
