import SwiftUI

struct FeedView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var feedService = FeedService.shared
    @State private var selectedTab = 0
    @State private var selectedPost: Post? = nil
    @State private var profileUserId: String? = nil
    @State private var isShowingProfile = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Takip / Keşfet seçici
                Picker("", selection: $selectedTab) {
                    Text("Takip").tag(0)
                    Text("Keşfet").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if feedService.isLoading {
                    Spacer()
                    ProgressView("Yükleniyor...")
                    Spacer()
                } else {
                    let posts = selectedTab == 0 ? feedService.feedPosts : feedService.discoverPosts
                    if posts.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(posts) { post in
                                    PostCard(
                                        post: post,
                                        currentUserId: authService.firebaseUser?.uid ?? "",
                                        onLike: { toggleLike(post: post) },
                                        onComment: { selectedPost = post },
                                        onUserTap: {
                                            profileUserId = post.userId
                                            isShowingProfile = true
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("Akış")
            .navigationDestination(item: $selectedPost) { post in
                PostDetailView(post: post, onLike: { toggleLike(post: post) })
                    .environmentObject(authService)
            }
            .sheet(isPresented: $isShowingProfile) {
                if let uid = profileUserId {
                    NavigationStack {
                        PublicProfileView(userId: uid)
                            .environmentObject(authService)
                    }
                }
            }
            .onAppear { startListening() }
            .onDisappear { feedService.stopListeners() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: selectedTab == 0 ? "person.2" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text(selectedTab == 0
                 ? "Henüz takip ettiğin kimse yok.\nKeşfet sekmesinden ilham al!"
                 : "Henüz gönderi yok.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private func startListening() {
        guard let uid = authService.firebaseUser?.uid else { return }
        feedService.startDiscoverListener(currentUserId: uid)
        SocialService.shared.fetchFollowingIds(userId: uid) { ids in
            feedService.startFeedListener(followingIds: ids, currentUserId: uid)
        }
    }

    private func toggleLike(post: Post) {
        guard let uid = authService.firebaseUser?.uid else { return }
        HapticManager.impact(.light)
        SocialService.shared.toggleLike(post: post, userId: uid) { _ in }
    }
}
