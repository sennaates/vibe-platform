import Foundation
import FirebaseFirestore

class SocialService: ObservableObject {
    static let shared = SocialService()
    private let db = Firestore.firestore()

    // MARK: - Beğeni

    func toggleLike(post: Post, user: SocialUser, completion: @escaping (Bool) -> Void) {
        let userId = user.id
        // Web ile aynı yapı: posts/{postId}/likes/{userId} subkoleksiyonu
        let likeRef     = db.collection("posts").document(post.id).collection("likes").document(userId)
        let postRef     = db.collection("posts").document(post.id)
        // Web ile ortak: userLikes/{uid}/items/{postId} — beğeni geçmişi için
        let userLikeRef = db.collection("userLikes").document(userId).collection("items").document(post.id)

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let likeDocument: DocumentSnapshot
            do {
                try likeDocument = transaction.getDocument(likeRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            if likeDocument.exists {
                transaction.deleteDocument(likeRef)
                transaction.deleteDocument(userLikeRef)
                transaction.updateData([
                    "likesCount": FieldValue.increment(Int64(-1)),
                    "likeCount":  FieldValue.increment(Int64(-1))
                ], forDocument: postRef)
                return false
            } else {
                transaction.setData([
                    "userId": userId,
                    "userName": user.displayName,
                    "userAvatar": user.avatarEmoji,
                    "userColor": user.profileColorRaw,
                    "postId": post.id,
                    "createdAt": FieldValue.serverTimestamp()
                ], forDocument: likeRef)
                
                transaction.setData([
                    "postId": post.id,
                    "likedAt": FieldValue.serverTimestamp()
                ], forDocument: userLikeRef)
                
                transaction.updateData([
                    "likesCount": FieldValue.increment(Int64(1)),
                    "likeCount":  FieldValue.increment(Int64(1))
                ], forDocument: postRef)
                return true
            }
        }) { [weak self] (result, error) in
            if let error = error {
                print("SocialService: Like transaction failed: \(error.localizedDescription)")
                completion(false)
            } else if let isLiked = result as? Bool {
                completion(isLiked)
                
                // Beğeni bildirimi — kendi gönderisine beğeni gelirse bildirim yok
                if isLiked && post.userId != userId {
                    self?.createNotification(
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

    // MARK: - Yorum

    func addComment(
        postId: String,
        text: String,
        user: SocialUser,
        replyToId: String? = nil,
        replyToName: String? = nil,
        completion: @escaping (Error?) -> Void
    ) {
        let commentRef = db.collection("posts").document(postId).collection("comments").document()
        let comment = Comment(
            id: commentRef.documentID,
            userId: user.id,
            userDisplayName: user.displayName,
            userAvatarEmoji: user.avatarEmoji,
            text: text,
            createdAt: Date(),
            replyToId: replyToId,
            replyToName: replyToName
        )
        commentRef.setData(comment.dict) { [weak self] error in
            guard let self else { return }
            if error == nil {
                self.db.collection("posts").document(postId)
                    .updateData([
                        "commentsCount": FieldValue.increment(Int64(1)),
                        "commentCount":  FieldValue.increment(Int64(1))
                    ])

                // Yorum bildirimi — post sahibine gönder
                self.db.collection("posts").document(postId).getDocument { snap, _ in
                    guard let data = snap?.data(),
                          let postOwnerId = data["userId"] as? String
                    else { return }
                    // iOS "imageURL" veya web "imageUrl" — her ikisini de dene
                    let postImageUrl = data["imageURL"] as? String
                                   ?? data["imageUrl"] as? String
                                   ?? ""

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

    func deleteComment(postId: String, commentId: String, completion: @escaping (Error?) -> Void) {
        let commentRef = db.collection("posts").document(postId).collection("comments").document(commentId)
        commentRef.delete { [weak self] error in
            if error == nil {
                self?.db.collection("posts").document(postId)
                    .updateData([
                        "commentsCount": FieldValue.increment(Int64(-1)),
                        "commentCount":  FieldValue.increment(Int64(-1))
                    ])
            }
            completion(error)
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
            ["followersCount": FieldValue.increment(Int64(1)),   // web canonical
             "followerCount":  FieldValue.increment(Int64(1))],  // ios eski
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
            ["followersCount": FieldValue.increment(Int64(-1)),
             "followerCount":  FieldValue.increment(Int64(-1))],
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
            .limit(to: 30)
            .getDocuments { snapshot, _ in
                let posts = snapshot?.documents.compactMap {
                    Post.from($0.data(), id: $0.documentID)
                } ?? []
                completion(posts)
            }
    }

    /// Cursor-based sayfalama ile kullanıcı gönderileri
    func fetchUserPostsPaginated(
        userId: String,
        limit: Int = 30,
        after lastDoc: DocumentSnapshot? = nil,
        completion: @escaping ([Post], DocumentSnapshot?) -> Void
    ) {
        var query = db.collection("posts")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let lastDoc {
            query = query.start(afterDocument: lastDoc)
        }

        query.getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("SocialService: query failed with orderBy, running fallback. Error: \(error.localizedDescription)")
                self?.db.collection("posts")
                    .whereField("userId", isEqualTo: userId)
                    .limit(to: 100)
                    .getDocuments { fallbackSnapshot, _ in
                        let docs  = fallbackSnapshot?.documents ?? []
                        var posts = docs.compactMap { Post.from($0.data(), id: $0.documentID) }
                        posts.sort { $0.createdAt > $1.createdAt }
                        completion(posts, nil)
                    }
            } else {
                let docs  = snapshot?.documents ?? []
                let posts = docs.compactMap { Post.from($0.data(), id: $0.documentID) }
                completion(posts, docs.last)
            }
        }
    }

    /// Kullanıcının beğendiği gönderiler — cursor-based sayfalama
    func fetchLikedPostsPaginated(
        userId: String,
        limit: Int = 30,
        after lastDoc: DocumentSnapshot? = nil,
        completion: @escaping ([Post], DocumentSnapshot?) -> Void
    ) {
        var query = db.collection("userLikes").document(userId).collection("items")
            .order(by: "likedAt", descending: true)
            .limit(to: limit)

        if let lastDoc {
            query = query.start(afterDocument: lastDoc)
        }

        query.getDocuments { [weak self] snapshot, _ in
            guard let self else { return }
            let docs    = snapshot?.documents ?? []
            let lastRef = docs.last
            let ids     = docs.compactMap { $0.data()["postId"] as? String }

            guard !ids.isEmpty else { completion([], nil); return }

            // Firestore `in` sorgusu — maks 30 ID (Firestore limiti 30)
            self.db.collection("posts")
                .whereField(FieldPath.documentID(), in: ids)
                .getDocuments { snap, _ in
                    let postMap = Dictionary(
                        uniqueKeysWithValues: (snap?.documents ?? []).compactMap { doc -> (String, Post)? in
                            guard let post = Post.from(doc.data(), id: doc.documentID) else { return nil }
                            return (doc.documentID, post)
                        }
                    )
                    // Beğeni sırasını koru
                    let ordered = ids.compactMap { postMap[$0] }
                    completion(ordered, lastRef)
                }
        }
    }

    // MARK: - Kullanıcı Ara

    func searchUsers(query: String, completion: @escaping ([SocialUser]) -> Void) {
        guard !query.isEmpty else { completion([]); return }
        let lowercaseQuery = query.lowercased()
        let end = lowercaseQuery + "\u{f8ff}"
        
        db.collection("users")
            .whereField("displayNameLowercase", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("displayNameLowercase", isLessThanOrEqualTo: end)
            .limit(to: 20)
            .getDocuments { [weak self] snapshot, _ in
                guard let self else { return }
                
                let users = snapshot?.documents.compactMap {
                    SocialUser.from($0.data(), id: $0.documentID)
                } ?? []
                
                if !users.isEmpty {
                    completion(users)
                } else {
                    // Fallback: fetch all users (limit to 100) and scan in-memory for case-insensitive matching
                    self.db.collection("users")
                        .limit(to: 100)
                        .getDocuments { fallbackSnapshot, _ in
                            let allUsers = fallbackSnapshot?.documents.compactMap {
                                SocialUser.from($0.data(), id: $0.documentID)
                            } ?? []
                            let filtered = allUsers.filter {
                                $0.displayName.localizedCaseInsensitiveContains(lowercaseQuery)
                            }
                            completion(Array(filtered.prefix(20)))
                        }
                }
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

        // Her iki sayaç adını düşür
        batch.updateData(
            ["postsCount": FieldValue.increment(Int64(-1)),  // web canonical
             "postCount":  FieldValue.increment(Int64(-1))], // ios eski
            forDocument: db.collection("users").document(post.userId)
        )

        batch.commit { error in
            if error == nil {
                // İlişkili beğenileri arka planda temizle — posts/{id}/likes subkoleksiyonu
                self.db.collection("posts").document(post.id).collection("likes")
                    .getDocuments { snapshot, _ in
                        snapshot?.documents.forEach { $0.reference.delete() }
                    }
            }
            completion(error)
        }
    }

    // MARK: - Trend Hashtagler
    func fetchTrendingHashtags(completion: @escaping ([(tag: String, count: Int)]) -> Void) {
        db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 200)
            .getDocuments { snap, _ in
                var map: [String: Int] = [:]
                snap?.documents.forEach { d in
                    let tags = d.data()["tags"] as? [String] ?? []
                    tags.forEach { map[$0] = (map[$0] ?? 0) + 1 }
                }
                let sorted = map
                    .sorted { $0.value > $1.value }
                    .prefix(12)
                    .map { (tag: $0.key, count: $0.value) }
                completion(Array(sorted))
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
