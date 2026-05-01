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
    @State private var followLoading = false

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

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
            }
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
                .frame(height: 110)

                // Avatar
                avatarView(emoji: user.avatarEmoji, color: user.profileColor.color, size: 82)
                    .shadow(color: user.profileColor.color.opacity(0.4), radius: 10, y: 3)
                    .overlay(
                        Circle()
                            .strokeBorder(Color(UIColor.systemBackground), lineWidth: 3)
                    )
                    .offset(y: 41)
            }

            // Bilgi alanı
            VStack(spacing: 12) {
                // İsim + bio
                VStack(spacing: 5) {
                    Text(user.displayName)
                        .font(.title3.weight(.bold))
                        .padding(.top, 48) // avatar için boşluk

                    if !user.bio.isEmpty {
                        Text(user.bio)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                // İstatistikler
                HStack(spacing: 0) {
                    statPill(value: user.postCount, label: "Gönderi")
                    Divider().frame(height: 30)
                    statPill(value: user.followerCount, label: "Takipçi")
                    Divider().frame(height: 30)
                    statPill(value: user.followingCount, label: "Takip")
                }
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 20)

                // Takip butonu
                if !isOwnProfile {
                    followButton(user: user)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
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
        VStack(alignment: .leading, spacing: 0) {
            if posts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Henüz gönderi yok")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(60)
            } else {
                Divider()
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(posts) { post in
                        AsyncImage(url: URL(string: post.imageURL)) { phase in
                            Group {
                                if case .success(let img) = phase {
                                    img.resizable().scaledToFill()
                                } else {
                                    Rectangle()
                                        .fill(post.emotion.color.opacity(0.15))
                                        .overlay(
                                            Text(post.emotion.emoji)
                                                .font(.title)
                                        )
                                }
                            }
                        }
                        .frame(
                            width: UIScreen.main.bounds.width / 3 - 1,
                            height: UIScreen.main.bounds.width / 3 - 1
                        )
                        .clipped()
                        .contentShape(Rectangle())
                        .onTapGesture { selectedPost = post }
                    }
                }
            }
        }
    }

    // MARK: - Veri Yükleme

    private func load() {
        let group = DispatchGroup()

        group.enter()
        Firestore.firestore().collection("users").document(userId).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                self.user = SocialUser.from(data, id: self.userId)
            }
            group.leave()
        }

        group.enter()
        SocialService.shared.fetchUserPosts(userId: userId) { fetched in
            self.posts = fetched
            group.leave()
        }

        if let currentId = authService.firebaseUser?.uid, currentId != userId {
            group.enter()
            SocialService.shared.isFollowing(targetUserId: userId, currentUserId: currentId) { following in
                self.isFollowing = following
                group.leave()
            }
        }

        group.notify(queue: .main) { self.isLoading = false }
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
        guard let uid = authService.firebaseUser?.uid else { return }
        SocialService.shared.toggleLike(post: post, userId: uid) { _ in }
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

