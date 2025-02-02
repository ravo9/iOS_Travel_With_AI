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
    private var locationRepository = LocationRepository()
    private var remoteConfigRepository = RemoteConfigRepository()
    private var imagesRepository = ImagesRepository()
    private var generativeModel = GenerativeModelRepository()
    
    @Published var uiState: UiState = .initial
    @Published var locationText: String = "Looking for your physical location by GPS..."
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
        uiState = .loading
        remoteConfigRepository.fetchApiKey(
            onSuccess: { [weak self] apiKey in
                self?.generativeModel.initializeModel(apiKey: apiKey)
                self?.uiState = .initial
            },
            onError: { [weak self] error in
                self?.uiState = .error("Problem with the server: " + error.localizedDescription)
            }
        )
    }

    func getAIGeneratedImages() -> [String] {
        return imagesRepository.getAIGeneratedImages()
    }
    
    func sendPrompt(messageType: MessageType, prompt: String? = nil, photo: Data? = nil, locationInput: String? = nil) async {
        uiState = .loading
        do {
            let location: String
            if let locationInput = locationInput {
                location = locationInput
            } else {
                guard let fetchedLocation = try await fetchCurrentLocation() else {
                    uiState = .error("Location not available")
                    return
                }
                location = getLocationString(location: fetchedLocation)
            }
            let enhancedPrompt = messageType.getMessage(location: location, prompt: prompt ?? "")
            guard let response = try await generateResponse(
                for: enhancedPrompt,
                photo: photo
            ) else {
                uiState = .error("Received empty response.")
                return
            }
            uiState = .success(cleanResponseText(response))
        } catch {
            uiState = .error(error.localizedDescription)
        }
    }

    func fetchCurrentLocation() async throws -> CLLocation? {
        do {
            if let location = try await locationRepository.getCurrentLocation() {
                
                // Temporary
                self.locationText = toDetailedString(location: location)
                
                return CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
            return nil
        } catch {
            return nil
        }
    }
    
    func userDeniedLocation(errorMessage: String) {
        self.locationText = errorMessage
    }

    private func generateResponse(for prompt: String, photo: Data?) async throws -> String? {
        do {
            return try await generativeModel.generateResponse(
                prompt: prompt,
                imageData: photo
            )
        } catch {
            throw error
        }
    }

    private func cleanResponseText(_ text: String) -> String {
        return text.replacingOccurrences(of: "**", with: "")
    }
    
    func toDetailedString(location: CLLocation) -> String {
        var details = "• Latitude: \(String(format: "%.4f", location.coordinate.latitude))\n"
        details += "• Longitude: \(String(format: "%.4f", location.coordinate.longitude))\n"
        if location.altitude != 0 {
            details += "• Altitude: \(String(format: "%.2f", location.altitude)) meters\n"
        }
        if location.horizontalAccuracy >= 0 {
            details += "• Accuracy: \(String(format: "%.2f", location.horizontalAccuracy)) meters"
        }
        return details
    }

    func getLocationString(location: CLLocation) -> String {
        return "Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)."
    }
}

enum UiState: Equatable {
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
            return "Tell me interesting things about this location: {location} Do not mention these values in response. Don't confirm you understand me. Behave like a tourist guide. Tell me about history, tourist spots, restaurants, etc."
        case .history:
            return "Tell me about history of this location: {location} Do not mention these values in response. Don't confirm you understand me. Behave like a tourist guide."
        case .restaurants:
            return "Tell me about restaurants and interesting food spots in a walking distance from this location: {location} Do not mention these values in response. Don't confirm you understand me. Mention restaurants' names!"
        case .touristSpots:
            return "Tell me about 5-6 most famous and important tourist spots/ attractions around this location that are worth to visit: {location} Do not mention these values in response. Don't confirm you understand me. Behave like a tourist guide."
        case .safety:
            return "Tell me about risks I should be careful on, and behaviours I should avoid as a tourist to stay safe in this location. Be specific. You can tell me also what behaviours should I avoid not to offend locals. Refer to this place specifically: {location} Do not mention these values in response. Don't confirm you understand me. Behave like a tourist guide."
        case .custom:
            return "{prompt}. Please answer in relation to the place: {location} Do not mention these values in response. Don't confirm you understand me."
        case .photo:
            return "{prompt}. Please tell me what is in the picture. Please answer in relation to the place: {location} Do not mention these values in response. Don't confirm you understand me."
        }
    }

    func getMessage(location: String, prompt: String = "") -> String {
        return template
            .replacingOccurrences(of: "{location}", with: location)
            .replacingOccurrences(of: "{prompt}", with: prompt)
    }
}
