//
//  VibeApp.swift
//  Vibe
//
//  Created by Sena Ateş on 29.04.2026.
//

import SwiftUI
import FirebaseCore

@main
struct VibeApp: App {
    @StateObject private var authService = AuthService.shared

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
    }
}
