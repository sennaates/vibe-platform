//
//  ContentView.swift
//  Vibe
//
//  Created by Sena Ateş on 29.04.2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView { hasCompletedOnboarding = true }
        } else if !authService.isLoggedIn {
            AuthView()
        } else {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        TabView {
            UserListView()
                .tabItem {
                    Label("Çizim", systemImage: "pencil.and.scribble")
                }

            FeedView()
                .tabItem {
                    Label("Akış", systemImage: "rectangle.stack")
                }

            PublicProfileView(userId: authService.firebaseUser?.uid ?? "")
                .tabItem {
                    Label("Profil", systemImage: "person.circle")
                }
        }
    }
}
