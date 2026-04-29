import SwiftUI
import FirebaseFirestore

struct PublicProfileView: View {
    @EnvironmentObject var authService: AuthService
    let userId: String

    @State private var user: SocialUser? = nil
    @State private var posts: [Post] = []
    @State private var isFollowing = false
    @State private var isLoading = true
    @State private var selectedPost: Post? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var isOwnProfile: Bool {
        userId == authService.firebaseUser?.uid
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView().padding(40)
                } else if let user {
                    profileHeader(user)
                    Divider()
                    postsGrid
                }
            }
        }
        .navigationTitle(user?.displayName ?? "Profil")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPost) { post in
            NavigationStack {
                PostDetailView(post: post, onLike: { toggleLike(post: post) })
                    .environmentObject(authService)
            }
        }
        .onAppear { load() }
    }

    private func profileHeader(_ user: SocialUser) -> some View {
        VStack(spacing: 16) {
            avatarView(emoji: user.avatarEmoji, color: user.profileColor.color, size: 80)

            Text(user.displayName)
                .font(.title2.weight(.bold))

            if !user.bio.isEmpty {
                Text(user.bio)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            HStack(spacing: 32) {
                statView(value: user.postCount, label: "Gönderi")
                statView(value: user.followerCount, label: "Takipçi")
                statView(value: user.followingCount, label: "Takip")
            }

            if !isOwnProfile {
                Button {
                    toggleFollow(user: user)
                } label: {
                    Text(isFollowing ? "Takibi Bırak" : "Takip Et")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isFollowing ? .primary : .white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 8)
                        .background(isFollowing
                                    ? Color(UIColor.secondarySystemBackground)
                                    : Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }

    private var postsGrid: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(posts) { post in
                AsyncImage(url: URL(string: post.imageURL)) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFill()
                    } else {
                        Rectangle().fill(post.emotion.color.opacity(0.15))
                    }
                }
                .frame(
                    width: UIScreen.main.bounds.width / 3,
                    height: UIScreen.main.bounds.width / 3
                )
                .clipped()
                .onTapGesture { selectedPost = post }
            }
        }
    }

    private func statView(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)").font(.title3.weight(.bold))
            Text(label).font(.caption).foregroundColor(.secondary)
        }
    }

    // MARK: - Veri Yükleme

    private func load() {
        let group = DispatchGroup()

        // Kullanıcıyı doğrudan Firestore'dan çek (AuthService'i bozmadan)
        group.enter()
        Firestore.firestore().collection("users").document(userId).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                self.user = SocialUser.from(data, id: self.userId)
            }
            group.leave()
        }

        // Gönderileri çek
        group.enter()
        SocialService.shared.fetchUserPosts(userId: userId) { fetched in
            self.posts = fetched
            group.leave()
        }

        // Takip durumu
        if let currentId = authService.firebaseUser?.uid, currentId != userId {
            group.enter()
            SocialService.shared.isFollowing(
                targetUserId: userId,
                currentUserId: currentId
            ) { following in
                self.isFollowing = following
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.isLoading = false
        }
    }

    // MARK: - Aksiyonlar

    private func toggleFollow(user: SocialUser) {
        guard let currentId = authService.firebaseUser?.uid else { return }
        HapticManager.impact(.medium)
        if isFollowing {
            SocialService.shared.unfollow(targetUserId: user.id, currentUserId: currentId) { _ in
                self.isFollowing = false
                self.user?.followerCount -= 1
            }
        } else {
            SocialService.shared.follow(targetUserId: user.id, currentUserId: currentId) { _ in
                self.isFollowing = true
                self.user?.followerCount += 1
            }
        }
    }

    private func toggleLike(post: Post) {
        guard let uid = authService.firebaseUser?.uid else { return }
        SocialService.shared.toggleLike(post: post, userId: uid) { _ in }
    }
}
