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
    @State private var isShowingEditProfile = false

    var body: some View {
        TabView {
            // Çizim
            UserListView()
                .tabItem {
                    Label("Çizim", systemImage: "pencil.and.scribble")
                }

            // Sosyal Akış
            FeedView()
                .tabItem {
                    Label("Akış", systemImage: "rectangle.stack")
                }

            // Kendi Profili
            NavigationStack {
                PublicProfileView(userId: authService.firebaseUser?.uid ?? "")
                    .environmentObject(authService)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Button {
                                    isShowingEditProfile = true
                                } label: {
                                    Label("Profili Düzenle", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    authService.signOut()
                                } label: {
                                    Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Profil", systemImage: "person.circle")
            }
        }
        .sheet(isPresented: $isShowingEditProfile) {
            EditProfileView()
                .environmentObject(authService)
        }
    }
}
