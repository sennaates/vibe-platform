import SwiftUI

struct FeedView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var feedService = FeedService.shared
    @State private var selectedTab = 1
    @State private var selectedPost: Post? = nil
    @State private var profileUserId: String? = nil
    @State private var isShowingProfile = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab seçici
                tabSelector
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)

                if feedService.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(AppColor.accent)
                    Spacer()
                } else {
                    let posts = selectedTab == 0 ? feedService.feedPosts : feedService.discoverPosts
                    if posts.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: AppSpacing.md) {
                                ForEach(posts) { post in
                                    PostCard(
                                        post: post,
                                        currentUserId: authService.firebaseUser?.uid ?? "",
                                        onLike: { toggleLike(post: post) },
                                        onComment: { selectedPost = post },
                                        onUserTap: {
                                            profileUserId = post.userId
                                            isShowingProfile = true
                                        },
                                        onDelete: { deletePost(post) }
                                    )
                                    .padding(.horizontal, AppSpacing.md)
                                }
                            }
                            .padding(.vertical, AppSpacing.md)
                        }
                    }
                }
            }
            .background(AppColor.canvas.ignoresSafeArea())
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

    // MARK: - Tab Seçici (Claude tarzı segmented)

    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "Takip", icon: "person.2.fill", index: 0)
            tabButton(title: "Keşfet", icon: "sparkles", index: 1)
        }
        .padding(3)
        .background(AppColor.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    private func tabButton(title: String, icon: String, index: Int) -> some View {
        let isSelected = selectedTab == index
        return Button {
            HapticManager.selection()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? AppColor.ink : AppColor.inkMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected ? AppColor.canvas : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm + 2, style: .continuous))
            .shadow(
                color: isSelected ? .black.opacity(0.06) : .clear,
                radius: 4, y: 1
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Boş Durum

    private var emptyState: some View {
        VStack {
            Spacer()
            EmptyStateView(
                icon: selectedTab == 0 ? "person.2" : "sparkles",
                title: selectedTab == 0 ? "Takip ettiğin yok" : "Henüz gönderi yok",
                message: selectedTab == 0
                    ? "Keşfet sekmesinden ilham al, takip etmek istediğin sanatçıları bul."
                    : "Topluluğun ilk gönderisi senden gelebilir."
            )
            Spacer()
        }
    }

    // MARK: - Aksiyonlar

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

    private func deletePost(_ post: Post) {
        SocialService.shared.deletePost(post) { _ in }
    }
}
