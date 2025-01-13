//
//  MainViewModel.swift
//  Travel with AI
//
//  Created by Rafal Ozog on 12/01/2025.
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

@MainActor
class MainViewModel: ObservableObject {
//    private var locationManager = LocationManager()
    private var imagesRepository = ImagesRepository()
    private var generativeModel = GenerativeModelRepository(apiKey: "")
    
    @Published var uiState: UiState = .initial
    var outputText: String {
            switch uiState {
            case .initial:
                return "(My answers will appear here)"
            case .loading:
                return "Loading..."
            case .success(let result):
                return result
            case .error(let errorMessage):
                return "Error: \(errorMessage)"
            }
        }
    
    init() {
        fetchApiKey()
    }

    func fetchApiKey() {
//        generativeModel.fetchApiKey(
//            onSuccess: { [weak self] apiKey in
//                self?.generativeModel.initializeModel(with: apiKey)
//            },
//            onError: { [weak self] in
//                self?.uiState = .error("Problem with the server.")
//            }
//        )
    }

    func getAIGeneratedImages() -> [String] {
        return imagesRepository.getAIGeneratedImages()
    }

    func sendPrompt(messageType: MessageType, prompt: String? = nil, photo: UIImage? = nil) async {
        uiState = .loading
        do {
//            let location = try await locationManager.getCurrentLocation()
            let location = CLLocation()
            guard let enhancedPrompt = enhancePrompt(messageType: messageType, location: location, prompt: prompt) else {
                uiState = .error("Prompt error.")
                return
            }
            
//            let response = try await generativeModel.generateResponse(for: enhancedPrompt, photo: photo)
            let response = "Testing Viewmodel"
            uiState = .success(cleanResponseText(response))
        } catch {
            uiState = .error(error.localizedDescription)
        }
    }
    
    private func cleanResponseText(_ text: String) -> String {
        return text.replacingOccurrences(of: "**", with: "")
    }

    private func enhancePrompt(messageType: MessageType, location: CLLocation, prompt: String?) -> String? {
        return messageType.getMessage(location: location, prompt: prompt ?? "")
    }
}

enum UiState {
    case initial
    case loading
    case success(String)
    case error(String)
}

enum MessageType {
    case initial
    case history
    case restaurants
    case touristSpots
    case safety
    case custom
    case photo

    var template: String {
        switch self {
        case .initial:
            return "Tell me interesting things about this location: Latitude: {latitude}, Longitude: {longitude}. Do not mention these values in response. Don't confirm you understand me. Behave like a tourist guide. Tell me about history, tourist spots, restaurants, etc."
        case .history:
            return "Tell me about history of this location: Latitude: {latitude}, Longitude: {longitude}. Do not mention these values in response. Don't confirm you understand me. Behave like a tourist guide."
        case .restaurants:
            return "Tell me about restaurants and interesting food spots in a walking distance from this location: Latitude: {latitude}, Longitude: {longitude}. Do not mention these values in response. Don't confirm you understand me. Mention restaurants' names!"
        case .touristSpots:
            return "Tell me about 5-6 most famous and important tourist spots/ attractions around this location that are worth to visit: Latitude: {latitude}, Longitude: {longitude}. Do not mention these values in response. Don't confirm you understand me. Behave like a tourist guide."
        case .safety:
            return "Tell me about risks I should be careful on, and behaviours I should avoid as a tourist to stay safe in this location. Be specific. You can tell me also what behaviours should I avoid not to offend locals. Refer to this place specifically: Latitude: {latitude}, Longitude: {longitude}. Do not mention these values in response. Don't confirm you understand me. Behave like a tourist guide."
        case .custom:
            return "{prompt}. Please answer in relation to the place: Latitude: {latitude}, Longitude: {longitude}. Do not mention these values in response. Don't confirm you understand me."
        case .photo:
            return "{prompt}. Please tell me what is in the picture. Please answer in relation to the place: Latitude: {latitude}, Longitude: {longitude}. Do not mention these values in response. Don't confirm you understand me."
        }
    }

    func getMessage(location: CLLocation, prompt: String = "") -> String {
        var message = template
        message = message.replacingOccurrences(of: "{latitude}", with: String(location.coordinate.latitude))
        message = message.replacingOccurrences(of: "{longitude}", with: String(location.coordinate.longitude))
        message = message.replacingOccurrences(of: "{prompt}", with: prompt)
        return message
    }
}
