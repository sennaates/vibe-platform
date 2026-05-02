import Foundation
import FirebaseFirestore

class SocialService: ObservableObject {
    static let shared = SocialService()
    private let db = Firestore.firestore()

    // MARK: - Beğeni

    func toggleLike(post: Post, userId: String, completion: @escaping (Bool) -> Void) {
        let likeId = "\(userId)_\(post.id)"
        let likeRef = db.collection("likes").document(likeId)
        let postRef = db.collection("posts").document(post.id)

        likeRef.getDocument { snapshot, _ in
            if snapshot?.exists == true {
                // Beğeniyi kaldır
                likeRef.delete()
                postRef.updateData(["likeCount": FieldValue.increment(Int64(-1))])
                completion(false)
            } else {
                // Beğen
                likeRef.setData(["userId": userId, "postId": post.id, "createdAt": Date()])
                postRef.updateData(["likeCount": FieldValue.increment(Int64(1))])
                completion(true)
            }
        }
    }

    // MARK: - Yorum

    func addComment(postId: String, text: String, user: SocialUser, completion: @escaping (Error?) -> Void) {
        let commentRef = db.collection("posts").document(postId).collection("comments").document()
        let comment = Comment(
            id: commentRef.documentID,
            userId: user.id,
            userDisplayName: user.displayName,
            userAvatarEmoji: user.avatarEmoji,
            text: text,
            createdAt: Date()
        )
        commentRef.setData(comment.dict) { error in
            if error == nil {
                self.db.collection("posts").document(postId)
                    .updateData(["commentCount": FieldValue.increment(Int64(1))])
            }
            completion(error)
        }
    }

    func fetchComments(postId: String, completion: @escaping ([Comment]) -> Void) {
        db.collection("posts").document(postId).collection("comments")
            .order(by: "createdAt", descending: false)
            .getDocuments { snapshot, _ in
                let comments = snapshot?.documents.compactMap {
                    Comment.from($0.data(), id: $0.documentID)
                } ?? []
                completion(comments)
            }
    }

    /// Gerçek zamanlı yorum listener — kayıt güncellendiğinde otomatik tetiklenir
    /// Returned ListenerRegistration üzerinden `.remove()` çağrılarak temizlenmelidir
    func listenComments(postId: String, onUpdate: @escaping ([Comment]) -> Void) -> ListenerRegistration {
        return db.collection("posts").document(postId).collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                let comments = snapshot?.documents.compactMap {
                    Comment.from($0.data(), id: $0.documentID)
                } ?? []
                onUpdate(comments)
            }
    }

    // MARK: - Takip

    func follow(targetUserId: String, currentUserId: String, completion: @escaping (Error?) -> Void) {
        let followId = "\(currentUserId)_\(targetUserId)"
        let batch = db.batch()

        let followRef = db.collection("follows").document(followId)
        batch.setData([
            "followerId": currentUserId,
            "followedId": targetUserId,
            "createdAt": Date()
        ], forDocument: followRef)

        batch.updateData(
            ["followingCount": FieldValue.increment(Int64(1))],
            forDocument: db.collection("users").document(currentUserId)
        )
        batch.updateData(
            ["followerCount": FieldValue.increment(Int64(1))],
            forDocument: db.collection("users").document(targetUserId)
        )

        batch.commit(completion: completion)
    }

    func unfollow(targetUserId: String, currentUserId: String, completion: @escaping (Error?) -> Void) {
        let followId = "\(currentUserId)_\(targetUserId)"
        let batch = db.batch()

        batch.deleteDocument(db.collection("follows").document(followId))
        batch.updateData(
            ["followingCount": FieldValue.increment(Int64(-1))],
            forDocument: db.collection("users").document(currentUserId)
        )
        batch.updateData(
            ["followerCount": FieldValue.increment(Int64(-1))],
            forDocument: db.collection("users").document(targetUserId)
        )

        batch.commit(completion: completion)
    }

    func isFollowing(targetUserId: String, currentUserId: String, completion: @escaping (Bool) -> Void) {
        let followId = "\(currentUserId)_\(targetUserId)"
        db.collection("follows").document(followId).getDocument { snapshot, _ in
            completion(snapshot?.exists == true)
        }
    }

    func fetchFollowingIds(userId: String, completion: @escaping ([String]) -> Void) {
        db.collection("follows")
            .whereField("followerId", isEqualTo: userId)
            .getDocuments { snapshot, _ in
                let ids = snapshot?.documents.compactMap {
                    $0.data()["followedId"] as? String
                } ?? []
                completion(ids)
            }
    }

    func fetchUserPosts(userId: String, completion: @escaping ([Post]) -> Void) {
        db.collection("posts")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, _ in
                let posts = snapshot?.documents.compactMap {
                    Post.from($0.data(), id: $0.documentID)
                } ?? []
                completion(posts)
            }
    }

    // MARK: - Gönderi Sil

    func deletePost(_ post: Post, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()

        // Gönderiyi sil
        batch.deleteDocument(db.collection("posts").document(post.id))

        // postCount'u düşür
        batch.updateData(
            ["postCount": FieldValue.increment(Int64(-1))],
            forDocument: db.collection("users").document(post.userId)
        )

        batch.commit { error in
            if error == nil {
                // İlişkili beğenileri arka planda temizle (non-blocking)
                self.db.collection("likes")
                    .whereField("postId", isEqualTo: post.id)
                    .getDocuments { snapshot, _ in
                        snapshot?.documents.forEach { $0.reference.delete() }
                    }
            }
            completion(error)
        }
    }
}
