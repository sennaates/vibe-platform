import SwiftUI
import FirebaseFirestore

struct HashtagFeedView: View {
    @EnvironmentObject var authService: AuthService
    let tag: String

    @State private var posts: [Post] = []
    @State private var isLoading = true
    @State private var isLoadingMore = false
    @State private var hasMore = true
    @State private var lastDoc: DocumentSnapshot? = nil
    @State private var selectedPost: Post? = nil

    private let db = Firestore.firestore()
    private let pageSize = 20

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
                            .onAppear {
                                if post.id == posts.last?.id { loadMore() }
                            }
                        }

                        if isLoadingMore {
                            ProgressView()
                                .tint(AppColor.accent)
                                .padding(.vertical, 16)
                        } else if !hasMore && !posts.isEmpty {
                            Text("Tüm gönderiler yüklendi")
                                .font(.system(size: 12))
                                .foregroundColor(AppColor.inkSubtle)
                                .padding(.vertical, 12)
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

    // MARK: - İlk Yükleme

    private func loadPosts() {
        isLoading = true
        db.collection("posts")
            .whereField("tags", arrayContains: tag)
            .order(by: "createdAt", descending: true)
            .limit(to: Int64(pageSize))
            .getDocuments { snap, _ in
                guard let snap else { isLoading = false; return }
                lastDoc = snap.documents.last
                hasMore = snap.documents.count == pageSize
                let fetched = snap.documents.compactMap { Post.from($0.data(), id: $0.documentID) }
                enrichLikes(posts: fetched) { enriched in
                    self.posts = enriched
                    self.isLoading = false
                }
            }
    }

    // MARK: - Daha Fazla Yükle

    private func loadMore() {
        guard !isLoadingMore, hasMore, let last = lastDoc else { return }
        isLoadingMore = true
        db.collection("posts")
            .whereField("tags", arrayContains: tag)
            .order(by: "createdAt", descending: true)
            .start(afterDocument: last)
            .limit(to: Int64(pageSize))
            .getDocuments { snap, _ in
                guard let snap else { isLoadingMore = false; return }
                lastDoc = snap.documents.last ?? lastDoc
                hasMore = snap.documents.count == pageSize
                let fetched = snap.documents.compactMap { Post.from($0.data(), id: $0.documentID) }
                enrichLikes(posts: fetched) { enriched in
                    self.posts.append(contentsOf: enriched)
                    self.isLoadingMore = false
                }
            }
    }

    // MARK: - Beğeni Zenginleştirme (posts/{id}/likes/{uid} subcollection)

    private func enrichLikes(posts: [Post], completion: @escaping ([Post]) -> Void) {
        guard let uid = authService.firebaseUser?.uid else { completion(posts); return }
        var enriched = posts
        let group = DispatchGroup()
        for i in enriched.indices {
            let postId = enriched[i].id
            group.enter()
            db.collection("posts").document(postId)
                .collection("likes").document(uid)
                .getDocument { snap, _ in
                    if snap?.exists == true { enriched[i].isLiked = true }
                    group.leave()
                }
        }
        group.notify(queue: .main) { completion(enriched) }
    }

    private func toggleLike(post: Post) {
        guard let uid = authService.firebaseUser?.uid else { return }
        HapticManager.impact(.light)
        SocialService.shared.toggleLike(post: post, userId: uid) { _ in }
    }
}
