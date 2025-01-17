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
        remoteConfigRepository.fetchApiKey(
            onSuccess: { [weak self] apiKey in
                self?.generativeModel.initializeModel(apiKey: apiKey)
            },
            onError: { [weak self] error in
                self?.uiState = .error("Problem with the server: " + error.localizedDescription)
            }
        )
    }

    func getAIGeneratedImages() -> [String] {
        return imagesRepository.getAIGeneratedImages()
    }
    
    func sendPrompt(messageType: MessageType, prompt: String? = nil, photo: Data? = nil) async {
        uiState = .loading
        do {
            guard try await checkAndRequestLocationPermission() else {
                uiState = .error("Location permission denied.")
                return
            }
            guard let location = try await fetchCurrentLocation() else {
                uiState = .error("Location not available")
                return
            }
            guard let enhancedPrompt = enhancePrompt(messageType: messageType, location: location, prompt: prompt) else {
                uiState = .error("Failed to enhance the prompt.")
                return
            }
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

    private func checkAndRequestLocationPermission() async throws -> Bool {
        let locationManager = CLLocationManager()
        let status = CLLocationManager.authorizationStatus()

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        case .notDetermined:
            return try await withCheckedThrowingContinuation { continuation in
                locationManager.requestWhenInUseAuthorization()
                locationManager.delegate = PermissionDelegate { granted in
                    if granted {
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                }
            }
        case .denied, .restricted:
            return false // Permission denied or restricted
        @unknown default:
            throw NSError(domain: "Unknown authorization status", code: -1, userInfo: nil)
        }
    }

    class PermissionDelegate: NSObject, CLLocationManagerDelegate {
        private let completion: (Bool) -> Void

        init(completion: @escaping (Bool) -> Void) {
            self.completion = completion
        }

        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            let status = CLLocationManager.authorizationStatus()
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                completion(true)
            case .denied, .restricted, .notDetermined:
                completion(false)
            @unknown default:
                completion(false)
            }
        }
    }

    private func fetchCurrentLocation() async throws -> CLLocation? {
        do {
            if let location = try await locationRepository.getCurrentLocation() {
                return CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
            return nil
        } catch {
            return nil
        }
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
