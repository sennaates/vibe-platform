import SwiftUI
import FirebaseFirestore

struct HashtagFeedView: View {
    @EnvironmentObject var authService: AuthService
    let tag: String

    @State private var posts: [Post] = []
    @State private var isLoading = true
    @State private var selectedPost: Post? = nil

    private let db = Firestore.firestore()

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(AppColor.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if posts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "number")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(AppColor.inkSubtle)
                    Text("Henüz gönderi yok")
                        .font(.headline)
                        .foregroundColor(AppColor.inkMuted)
                    Text("#\(tag) etiketiyle paylaşım yap!")
                        .font(.subheadline)
                        .foregroundColor(AppColor.inkSubtle)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.md) {
                        ForEach(posts) { post in
                            PostCard(
                                post: post,
                                currentUserId: authService.firebaseUser?.uid ?? "",
                                onLike: { toggleLike(post: post) },
                                onComment: { selectedPost = post },
                                onUserTap: {}
                            )
                            .padding(.horizontal, AppSpacing.md)
                        }
                    }
                    .padding(.vertical, AppSpacing.md)
                }
            }
        }
        .background(AppColor.canvas.ignoresSafeArea())
        .navigationTitle("#\(tag)")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selectedPost) { post in
            PostDetailView(post: post, onLike: { toggleLike(post: post) })
                .environmentObject(authService)
        }
        .onAppear { loadPosts() }
    }

    // MARK: - Yükleme

    private func loadPosts() {
        isLoading = true
        db.collection("posts")
            .whereField("tags", arrayContains: tag)
            .order(by: "createdAt", descending: true)
            .limit(to: 30)
            .getDocuments { snap, _ in
                let uid = authService.firebaseUser?.uid ?? ""
                let fetched = snap?.documents.compactMap { d -> Post? in
                    Post.from(d.data(), id: d.documentID)
                } ?? []
                // Mark liked
                let group = DispatchGroup()
                var likedIds = Set<String>()
                for post in fetched {
                    group.enter()
                    Firestore.firestore()
                        .collection("likes")
                        .document("\(uid)_\(post.id)")
                        .getDocument { s, _ in
                            if s?.exists == true { likedIds.insert(post.id) }
                            group.leave()
                        }
                }
                group.notify(queue: .main) {
                    self.posts = fetched.map { p in
                        var copy = p
                        copy.isLiked = likedIds.contains(p.id)
                        return copy
                    }
                    self.isLoading = false
                }
            }
    }

    private func toggleLike(post: Post) {
        guard let uid = authService.firebaseUser?.uid else { return }
        HapticManager.impact(.light)
        SocialService.shared.toggleLike(post: post, userId: uid) { _ in }
    }
}
