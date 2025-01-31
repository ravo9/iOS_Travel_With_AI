//
//  RemoteConfigRepository.swift
//  Travel with AI
//
//  Created by Rafal Ozog on 13/01/2025.
//

import Foundation
import Firebase
import FirebaseRemoteConfig

class RemoteConfigRepository {
    private let remoteConfig: RemoteConfig

    init() {
        self.remoteConfig = RemoteConfig.remoteConfig()
        configureRemoteConfig()
    }
    
    private func configureRemoteConfig() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 20
        self.remoteConfig.configSettings = settings
    }

    func fetchApiKey(onSuccess: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        remoteConfig.fetchAndActivate { status, error in
            if let error = error {
                onError(error)
                return
            }
            if status == .successFetchedFromRemote || status == .successUsingPreFetchedData {
                let apiKey = self.remoteConfig["api_key"].stringValue
                if !apiKey.isEmpty {
                    onSuccess(apiKey)
                } else {
                    onError(NSError(domain: "RemoteConfigError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Fetch failed (received API key is null or empty)."]))
                }
            } else {
                onError(NSError(domain: "RemoteConfigError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Fetch failed (returned status is not right)."]))
            }
        }
    }
}
