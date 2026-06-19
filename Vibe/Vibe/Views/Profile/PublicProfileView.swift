import SwiftUI
import FirebaseFirestore

struct FollowsListNavTag: Identifiable, Hashable {
    let id = UUID()
    let userId: String
    let mode: FollowsListMode
}

struct PublicProfileView: View {
    @EnvironmentObject var authService: AuthService
    let userId: String

    @State private var user: SocialUser? = nil
    @State private var isFollowing = false
    @State private var isLoading = true
    @State private var selectedPost: Post? = nil
    @State private var followLoading = false
    @State private var hashtagNavTag: HashtagNavItem? = nil
    @State private var followsListNavTag: FollowsListNavTag? = nil

    // Sekmeler (kendi profili için ikinci sekme görünür)
    @State private var selectedTab = 0   // 0 = gönderiler, 1 = beğendikleri

    // Gönderi sayfalama
    @State private var posts: [Post] = []
    @State private var lastPostDoc: DocumentSnapshot? = nil
    @State private var hasMorePosts = false
    @State private var isLoadingMorePosts = false

    // Beğenilen gönderi sayfalama
    @State private var likedPosts: [Post] = []
    @State private var lastLikedDoc: DocumentSnapshot? = nil
    @State private var hasMoreLiked = false
    @State private var isLoadingMoreLiked = false

    @Environment(\.horizontalSizeClass) private var sizeClass

    private let pageSize = 30

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 4 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 2), count: count)
    }

    var isOwnProfile: Bool { userId == authService.firebaseUser?.uid }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if isLoading {
                    loadingView
                } else if let user {
                    profileHeader(user)
                    postsSection
                }
            }
        }
        .navigationTitle(user?.displayName ?? "Profil")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPost) { post in
            NavigationStack {
                PostDetailView(
                    post: post,
                    onLike: { toggleLike(post: post) },
                    onDelete: isOwnProfile ? { deletePost(post) } : nil
                )
                .environmentObject(authService)
                .navigationDestination(item: $hashtagNavTag) { item in
                    HashtagFeedView(tag: item.tag)
                        .environmentObject(authService)
                }
            }
        }
        .navigationDestination(item: $followsListNavTag) { tag in
            FollowsListView(userId: tag.userId, mode: tag.mode)
                .environmentObject(authService)
        }
        .onAppear { load() }
    }

    // MARK: - Yükleniyor

    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 60)
            ProgressView()
                .scaleEffect(1.3)
                .tint(.secondary)
            Text("Yükleniyor...")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Profil Başlığı

    private func profileHeader(_ user: SocialUser) -> some View {
        VStack(spacing: 0) {
            // Banner
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        user.profileColor.color.opacity(0.70),
                        user.profileColor.color.opacity(0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: sizeClass == .regular ? 160 : 110)

                // Avatar
                avatarView(emoji: user.avatarEmoji, color: user.profileColor.color, size: sizeClass == .regular ? 100 : 82)
                    .shadow(color: user.profileColor.color.opacity(0.4), radius: 10, y: 3)
                    .overlay(
                        Circle()
                            .strokeBorder(Color(UIColor.systemBackground), lineWidth: 3)
                    )
                    .offset(y: sizeClass == .regular ? 50 : 41)
            }

            // Bilgi alanı
            VStack(spacing: 12) {
                // İsim + bio
                VStack(spacing: 5) {
                    Text(user.displayName)
                        .font(sizeClass == .regular ? .title2.weight(.bold) : .title3.weight(.bold))
                        .padding(.top, sizeClass == .regular ? 58 : 48)

                    if !user.bio.isEmpty {
                        Text(user.bio)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, sizeClass == .regular ? 80 : 32)
                    }
                }

                // İstatistikler
                HStack(spacing: 0) {
                    statPill(value: user.postCount, label: "Gönderi")
                    Divider().frame(height: 30)
                    
                    Button {
                        HapticManager.impact(.light)
                        followsListNavTag = FollowsListNavTag(userId: userId, mode: .followers)
                    } label: {
                        statPill(value: user.followerCount, label: "Takipçi")
                    }
                    .buttonStyle(.plain)
                    
                    Divider().frame(height: 30)
                    
                    Button {
                        HapticManager.impact(.light)
                        followsListNavTag = FollowsListNavTag(userId: userId, mode: .following)
                    } label: {
                        statPill(value: user.followingCount, label: "Takip")
                    }
                    .buttonStyle(.plain)
                }
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, sizeClass == .regular ? 60 : 20)
                .frame(maxWidth: sizeClass == .regular ? 500 : .infinity)

                // Takip butonu
                if !isOwnProfile {
                    followButton(user: user)
                        .padding(.horizontal, sizeClass == .regular ? 60 : 20)
                        .frame(maxWidth: sizeClass == .regular ? 500 : .infinity)
                }

                // Sekme seçici — kendi profili için göster
                if isOwnProfile {
                    Picker("", selection: $selectedTab) {
                        Image(systemName: "square.grid.3x3").tag(0)
                        Image(systemName: "heart").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, sizeClass == .regular ? 60 : 20)
                    .frame(maxWidth: sizeClass == .regular ? 500 : .infinity)
                    .onChange(of: selectedTab) { _, tab in
                        if tab == 1 && likedPosts.isEmpty { loadLikedPosts() }
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }

    private func statPill(value: Int, label: String) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.title3.weight(.bold))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func followButton(user: SocialUser) -> some View {
        Button {
            toggleFollow(user: user)
        } label: {
            HStack(spacing: 6) {
                if followLoading {
                    ProgressView().tint(isFollowing ? .primary : .white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isFollowing ? "checkmark" : "person.badge.plus")
                        .font(.system(size: 13, weight: .semibold))
                    Text(isFollowing ? "Takip Ediliyor" : "Takip Et")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background {
                if isFollowing {
                    Color(UIColor.secondarySystemBackground)
                } else {
                    LinearGradient(
                        colors: [user.profileColor.color, user.profileColor.color.opacity(0.75)],
                        startPoint: .leading, endPoint: .trailing
                    )
                }
            }
            .foregroundColor(isFollowing ? .primary : .white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isFollowing ? Color(UIColor.separator) : Color.clear, lineWidth: 1)
            )
        }
        .disabled(followLoading)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isFollowing)
    }

    // MARK: - Gönderiler Grid

    private var postsSection: some View {
        VStack(spacing: 0) {
            Divider()

            let displayedPosts = selectedTab == 0 ? posts : likedPosts
            let isEmpty        = displayedPosts.isEmpty

            if isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: selectedTab == 0 ? "photo.on.rectangle.angled" : "heart.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text(selectedTab == 0 ? "Henüz gönderi yok" : "Henüz beğenilen gönderi yok")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(60)
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(displayedPosts) { post in
                        postCell(post)
                    }
                }

                // Load-more footer
                let hasMore     = selectedTab == 0 ? hasMorePosts     : hasMoreLiked
                let isLoading   = selectedTab == 0 ? isLoadingMorePosts : isLoadingMoreLiked

                if hasMore {
                    Button {
                        if selectedTab == 0 { loadMorePosts() } else { loadMoreLikedPosts() }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .padding(.vertical, 20)
                        } else {
                            Text("Daha Fazla")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 20)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(isLoading)
                }
            }
        }
    }

    @ViewBuilder
    private func postCell(_ post: Post) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fill)
            .overlay(
                AsyncImage(url: URL(string: post.imageURL)) { phase in
                    switch phase {
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        Rectangle()
                            .fill(post.emotion.color.opacity(0.15))
                            .overlay(Text(post.emotion.emoji).font(.title))
                    @unknown default:
                        EmptyView()
                    }
                }
            )
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture { selectedPost = post }
    }

    // MARK: - Veri Yükleme

    private func load() {
        let group = DispatchGroup()
        
        // Defansif zaman aşımı: Eğer 4.0 saniye içinde veriler yüklenmezse isLoading'i false yap
        var hasFinished = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            if !hasFinished {
                print("PublicProfileView: Yükleme zaman aşımına uğradı, fallback devreye giriyor.")
                self.isLoading = false
            }
        }

        group.enter()
        Firestore.firestore().collection("users").document(userId).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                self.user = SocialUser.from(data, id: self.userId)
            }
            group.leave()
        }

        group.enter()
        SocialService.shared.fetchUserPostsPaginated(userId: userId, limit: pageSize) { fetched, last in
            self.posts       = fetched
            self.lastPostDoc = last
            self.hasMorePosts = fetched.count == self.pageSize
            group.leave()
        }

        if let currentId = authService.firebaseUser?.uid, currentId != userId {
            group.enter()
            SocialService.shared.isFollowing(targetUserId: userId, currentUserId: currentId) { following in
                self.isFollowing = following
                group.leave()
            }
        }

        group.notify(queue: .main) {
            hasFinished = true
            self.isLoading = false
        }
    }

    private func loadMorePosts() {
        guard hasMorePosts, !isLoadingMorePosts else { return }
        isLoadingMorePosts = true
        SocialService.shared.fetchUserPostsPaginated(userId: userId, limit: pageSize, after: lastPostDoc) { fetched, last in
            self.posts.append(contentsOf: fetched)
            self.lastPostDoc       = last
            self.hasMorePosts      = fetched.count == self.pageSize
            self.isLoadingMorePosts = false
        }
    }

    private func loadLikedPosts() {
        guard !isLoadingMoreLiked else { return }
        isLoadingMoreLiked = true
        SocialService.shared.fetchLikedPostsPaginated(userId: userId, limit: pageSize) { fetched, last in
            self.likedPosts    = fetched
            self.lastLikedDoc  = last
            self.hasMoreLiked  = fetched.count == self.pageSize
            self.isLoadingMoreLiked = false
        }
    }

    private func loadMoreLikedPosts() {
        guard hasMoreLiked, !isLoadingMoreLiked else { return }
        isLoadingMoreLiked = true
        SocialService.shared.fetchLikedPostsPaginated(userId: userId, limit: pageSize, after: lastLikedDoc) { fetched, last in
            self.likedPosts.append(contentsOf: fetched)
            self.lastLikedDoc       = last
            self.hasMoreLiked       = fetched.count == self.pageSize
            self.isLoadingMoreLiked = false
        }
    }

    // MARK: - Aksiyonlar

    private func toggleFollow(user: SocialUser) {
        guard let currentId = authService.firebaseUser?.uid else { return }
        HapticManager.impact(.medium)
        followLoading = true
        if isFollowing {
            SocialService.shared.unfollow(targetUserId: user.id, currentUserId: currentId) { _ in
                self.isFollowing = false
                self.user?.followerCount -= 1
                self.followLoading = false
            }
        } else {
            SocialService.shared.follow(targetUserId: user.id, currentUserId: currentId) { _ in
                self.isFollowing = true
                self.user?.followerCount += 1
                self.followLoading = false
            }
        }
    }

    private func toggleLike(post: Post) {
        guard let user = authService.socialUser else { return }
        SocialService.shared.toggleLike(post: post, user: user) { _ in }
    }

    private func deletePost(_ post: Post) {
        SocialService.shared.deletePost(post) { error in
            if error == nil {
                self.posts.removeAll { $0.id == post.id }
                self.selectedPost = nil
            }
        }
    }
}

