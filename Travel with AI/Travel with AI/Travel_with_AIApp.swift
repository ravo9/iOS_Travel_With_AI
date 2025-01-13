//
//  Travel_with_AIApp.swift
//  Travel with AI
//
//  Created by Rafal Ozog on 12/01/2025.
//

import SwiftUI
import Firebase

@main
struct Travel_with_AIApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            MainScreenView()
        }
    }
}
