//
//  ContentView.swift
//  Vibe
//
//  Created by Sena Ateş on 29.04.2026.
//

import SwiftUI
import FirebaseFirestore

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
    @State private var isShowingSettings    = false
    @State private var unreadCount: Int     = 0
    @State private var notifListener: (any ListenerRegistration)?

    private let social = SocialService.shared

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

            // Ara
            SearchView()
                .environmentObject(authService)
                .tabItem {
                    Label("Ara", systemImage: "magnifyingglass")
                }

            // Bildirimler
            NotificationsView()
                .environmentObject(authService)
                .tabItem {
                    Label("Bildirimler", systemImage: "bell")
                }
                .badge(unreadCount > 0 ? unreadCount : 0)

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

                                Button {
                                    isShowingSettings = true
                                } label: {
                                    Label("Ayarlar", systemImage: "gearshape")
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
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
                .environmentObject(authService)
        }
        .onAppear { startUnreadListener() }
        .onDisappear { notifListener?.remove() }
    }

    private func startUnreadListener() {
        guard let uid = authService.firebaseUser?.uid else { return }
        notifListener = social.unreadNotificationCount(userId: uid) { count in
            unreadCount = count
        }
    }
}
