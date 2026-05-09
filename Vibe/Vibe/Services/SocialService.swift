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

        likeRef.getDocument { [weak self] snapshot, _ in
            guard let self else { return }
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

                // Beğeni bildirimi — kendi gönderine beğeni varsa bildirim yok
                if post.userId != userId {
                    self.db.collection("users").document(userId).getDocument { snap, _ in
                        guard let data = snap?.data(),
                              let user = SocialUser.from(data, id: userId) else { return }
                        self.createNotification(
                            targetUserId:   post.userId,
                            type:           "like",
                            fromUserId:     userId,
                            fromUserName:   user.displayName,
                            fromUserAvatar: user.avatarEmoji,
                            fromUserColor:  user.profileColorRaw,
                            postId:         post.id,
                            postImageUrl:   post.imageURL
                        )
                    }
                }
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
        commentRef.setData(comment.dict) { [weak self] error in
            guard let self else { return }
            if error == nil {
                self.db.collection("posts").document(postId)
                    .updateData(["commentCount": FieldValue.increment(Int64(1))])

                // Yorum bildirimi — post sahibine gönder
                self.db.collection("posts").document(postId).getDocument { snap, _ in
                    guard let data = snap?.data(),
                          let postOwnerId = data["userId"] as? String,
                          let postImageUrl = data["imageURL"] as? String
                    else { return }

                    self.createNotification(
                        targetUserId:   postOwnerId,
                        type:           "comment",
                        fromUserId:     user.id,
                        fromUserName:   user.displayName,
                        fromUserAvatar: user.avatarEmoji,
                        fromUserColor:  user.profileColorRaw,
                        postId:         postId,
                        postImageUrl:   postImageUrl
                    )
                }
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

        batch.commit { error in
            completion(error)
            if error == nil {
                // Takip bildirimi gönder — takipçinin profilini okuyarak isim/emoji al
                self.db.collection("users").document(currentUserId).getDocument { snap, _ in
                    guard let data = snap?.data(),
                          let user = SocialUser.from(data, id: currentUserId) else { return }
                    self.createNotification(
                        targetUserId:    targetUserId,
                        type:            "follow",
                        fromUserId:      currentUserId,
                        fromUserName:    user.displayName,
                        fromUserAvatar:  user.avatarEmoji,
                        fromUserColor:   user.profileColorRaw
                    )
                }
            }
        }
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

    // MARK: - Kullanıcı Ara

    func searchUsers(query: String, completion: @escaping ([SocialUser]) -> Void) {
        guard !query.isEmpty else { completion([]); return }
        let end = query + "\u{f8ff}"
        db.collection("users")
            .whereField("displayName", isGreaterThanOrEqualTo: query)
            .whereField("displayName", isLessThanOrEqualTo: end)
            .limit(to: 20)
            .getDocuments { snapshot, _ in
                let users = snapshot?.documents.compactMap {
                    SocialUser.from($0.data(), id: $0.documentID)
                } ?? []
                completion(users)
            }
    }

    // MARK: - Bildirimler

    func listenNotifications(userId: String, onUpdate: @escaping ([AppNotification]) -> Void) -> ListenerRegistration {
        return db.collection("notifications").document(userId).collection("items")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, _ in
                let notifs = snapshot?.documents.compactMap { doc -> AppNotification? in
                    var data = doc.data()
                    // Firestore Timestamp → Date
                    if let ts = data["createdAt"] as? Timestamp {
                        data["createdAt"] = ts.dateValue()
                    }
                    return AppNotification.from(data, id: doc.documentID)
                } ?? []
                onUpdate(notifs)
            }
    }

    func markAllNotificationsRead(userId: String) {
        db.collection("notifications").document(userId).collection("items")
            .whereField("read", isEqualTo: false)
            .getDocuments { snapshot, _ in
                let batch = self.db.batch()
                snapshot?.documents.forEach { doc in
                    batch.updateData(["read": true], forDocument: doc.reference)
                }
                batch.commit(completion: nil)
            }
    }

    func unreadNotificationCount(userId: String, completion: @escaping (Int) -> Void) -> ListenerRegistration {
        return db.collection("notifications").document(userId).collection("items")
            .whereField("read", isEqualTo: false)
            .addSnapshotListener { snapshot, _ in
                completion(snapshot?.documents.count ?? 0)
            }
    }

    func createNotification(
        targetUserId: String,
        type: String,
        fromUserId: String,
        fromUserName: String,
        fromUserAvatar: String,
        fromUserColor: String,
        postId: String? = nil,
        postImageUrl: String? = nil
    ) {
        guard targetUserId != fromUserId else { return }
        var data: [String: Any] = [
            "type": type,
            "fromUserId": fromUserId,
            "fromUserName": fromUserName,
            "fromUserAvatar": fromUserAvatar,
            "fromUserColor": fromUserColor,
            "read": false,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let postId       { data["postId"]       = postId }
        if let postImageUrl { data["postImageUrl"] = postImageUrl }

        db.collection("notifications").document(targetUserId).collection("items")
            .addDocument(data: data, completion: nil)
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

    // MARK: - Şikayet
    func reportPost(postId: String, reportedBy: String, completion: @escaping (Error?) -> Void) {
        db.collection("reports").addDocument(data: [
            "postId":      postId,
            "reportedBy":  reportedBy,
            "createdAt":   FieldValue.serverTimestamp()
        ]) { error in
            completion(error)
        }
    }
}
