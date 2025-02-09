//
//  Travel_with_AIApp.swift
//  Travel with AI
//
//  Created by Rafal Ozog on 12/01/2025.
//

import SwiftUI
import Firebase
import FirebaseAnalytics

@main
struct Travel_with_AIApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate // Firebase

    var body: some Scene {
        WindowGroup {
            MainScreenView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        Analytics.logEvent("ios_app_open", parameters: nil) // Firebase somehow needs it to kick off Analytics
        return true
    }
}
