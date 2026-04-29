import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit

class FeedService: ObservableObject {
    static let shared = FeedService()

    @Published var discoverPosts: [Post] = []
    @Published var feedPosts: [Post] = []
    @Published var isLoading = false

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var discoverListener: ListenerRegistration?
    private var feedListener: ListenerRegistration?

    // MARK: - Keşfet

    func startDiscoverListener(currentUserId: String) {
        discoverListener?.remove()
        isLoading = true
        discoverListener = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                var posts = snapshot?.documents.compactMap {
                    Post.from($0.data(), id: $0.documentID)
                } ?? []
                self.enrichWithLikes(posts: &posts, userId: currentUserId) { enriched in
                    self.discoverPosts = enriched
                    self.isLoading = false
                }
            }
    }

    // MARK: - Takip Akışı

    func startFeedListener(followingIds: [String], currentUserId: String) {
        feedListener?.remove()
        guard !followingIds.isEmpty else {
            feedPosts = []
            return
        }
        let ids = Array(followingIds.prefix(30))
        feedListener = db.collection("posts")
            .whereField("userId", in: ids)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                var posts = snapshot?.documents.compactMap {
                    Post.from($0.data(), id: $0.documentID)
                } ?? []
                self.enrichWithLikes(posts: &posts, userId: currentUserId) { enriched in
                    self.feedPosts = enriched
                }
            }
    }

    func stopListeners() {
        discoverListener?.remove()
        feedListener?.remove()
    }

    // MARK: - Paylaş

    func sharePost(
        image: UIImage,
        emotion: EmotionState,
        caption: String,
        user: SocialUser,
        completion: @escaping (Error?) -> Void
    ) {
        isLoading = true
        uploadImage(image) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                DispatchQueue.main.async { self.isLoading = false }
                completion(error)
            case .success(let url):
                let ref = self.db.collection("posts").document()
                let post = Post(
                    id: ref.documentID,
                    userId: user.id,
                    userDisplayName: user.displayName,
                    userAvatarEmoji: user.avatarEmoji,
                    userProfileColorRaw: user.profileColorRaw,
                    imageURL: url,
                    emotion: emotion,
                    caption: caption,
                    likeCount: 0,
                    commentCount: 0,
                    createdAt: Date()
                )
                ref.setData(post.dict) { error in
                    DispatchQueue.main.async { self.isLoading = false }
                    if error == nil {
                        self.db.collection("users").document(user.id)
                            .updateData(["postCount": FieldValue.increment(Int64(1))])
                    }
                    completion(error)
                }
            }
        }
    }

    // MARK: - Görsel Yükleme

    private func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.75) else {
            completion(.failure(NSError(domain: "VibeFeed", code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Görsel dönüştürülemedi"])))
            return
        }
        let ref = storage.reference().child("posts/\(UUID().uuidString).jpg")
        ref.putData(data) { _, error in
            if let error { completion(.failure(error)); return }
            ref.downloadURL { url, error in
                if let error { completion(.failure(error)); return }
                completion(.success(url?.absoluteString ?? ""))
            }
        }
    }

    // MARK: - Beğeni Zenginleştirme

    private func enrichWithLikes(
        posts: inout [Post],
        userId: String,
        completion: @escaping ([Post]) -> Void
    ) {
        var enriched = posts
        let group = DispatchGroup()

        for i in enriched.indices {
            let likeId = "\(userId)_\(enriched[i].id)"
            group.enter()
            db.collection("likes").document(likeId).getDocument { snapshot, _ in
                if snapshot?.exists == true {
                    enriched[i].isLiked = true
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(enriched)
        }
    }
}
