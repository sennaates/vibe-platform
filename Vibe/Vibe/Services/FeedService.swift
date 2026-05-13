import Foundation
import FirebaseFirestore
import UIKit

class FeedService: ObservableObject {
    static let shared = FeedService()

    @Published var discoverPosts: [Post] = []
    @Published var feedPosts: [Post] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMoreDiscover = true

    private let db = Firestore.firestore()
    private var discoverListener: ListenerRegistration?
    private var feedListener: ListenerRegistration?
    private var lastDiscoverDoc: DocumentSnapshot? = nil
    private let pageSize = 20

    // MARK: - Cloudinary Ayarları
    // Cloudinary dashboard'dan alınan değerleri buraya gir
    private let cloudinaryCloudName = "dy99f2dhb"
    private let cloudinaryUploadPreset = "jrgskcq4"

    // MARK: - Keşfet

    func startDiscoverListener(currentUserId: String) {
        discoverListener?.remove()
        isLoading = true
        lastDiscoverDoc = nil
        hasMoreDiscover = true
        discoverListener = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: Int64(pageSize))
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let snap = snapshot else { return }
                self.lastDiscoverDoc = snap.documents.last
                self.hasMoreDiscover = snap.documents.count == self.pageSize
                var posts = snap.documents.compactMap {
                    Post.from($0.data(), id: $0.documentID)
                }
                self.enrichWithLikes(posts: &posts, userId: currentUserId) { enriched in
                    self.discoverPosts = enriched
                    self.isLoading = false
                }
            }
    }

    func loadMoreDiscover(currentUserId: String) {
        guard !isLoadingMore, hasMoreDiscover, let lastDoc = lastDiscoverDoc else { return }
        isLoadingMore = true
        db.collection("posts")
            .order(by: "createdAt", descending: true)
            .start(afterDocument: lastDoc)
            .limit(to: Int64(pageSize))
            .getDocuments { [weak self] snapshot, _ in
                guard let self, let snap = snapshot else {
                    self?.isLoadingMore = false
                    return
                }
                self.lastDiscoverDoc = snap.documents.last ?? self.lastDiscoverDoc
                self.hasMoreDiscover = snap.documents.count == self.pageSize
                var newPosts = snap.documents.compactMap {
                    Post.from($0.data(), id: $0.documentID)
                }
                self.enrichWithLikes(posts: &newPosts, userId: currentUserId) { enriched in
                    self.discoverPosts.append(contentsOf: enriched)
                    self.isLoadingMore = false
                }
            }
    }

    // MARK: - Takip Akışı

    func startFeedListener(followingIds: [String], currentUserId: String) {
        feedListener?.remove()
        guard !followingIds.isEmpty else { feedPosts = []; return }
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

    // MARK: - Gönderi Paylaş

    func sharePost(
        image: UIImage,
        emotion: EmotionState,
        bpm: Int = 72,
        caption: String,
        user: SocialUser,
        completion: @escaping (Error?) -> Void
    ) {
        DispatchQueue.main.async { self.isLoading = true }

        uploadToCloudinary(image) { [weak self] result in
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
                    bpm: bpm,
                    caption: caption,
                    likeCount: 0,
                    commentCount: 0,
                    createdAt: Date()
                )
                ref.setData(post.dict) { error in
                    DispatchQueue.main.async { self.isLoading = false }
                    if error == nil {
                        self.db.collection("users").document(user.id)
                            .updateData([
                                "postsCount": FieldValue.increment(Int64(1)),  // web canonical
                                "postCount":  FieldValue.increment(Int64(1))   // ios eski
                            ])
                    }
                    completion(error)
                }
            }
        }
    }

    // MARK: - Cloudinary Yükleme

    private func uploadToCloudinary(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.75) else {
            completion(.failure(NSError(domain: "VibeFeed", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Görsel dönüştürülemedi"])))
            return
        }

        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudinaryCloudName)/image/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        // upload_preset
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(cloudinaryUploadPreset)\r\n".data(using: .utf8)!)
        // file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"drawing.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let secureUrl = json["secure_url"] as? String
            else {
                completion(.failure(NSError(domain: "VibeFeed", code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Cloudinary yanıtı okunamadı"])))
                return
            }
            completion(.success(secureUrl))
        }.resume()
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
            let postId = enriched[i].id
            group.enter()
            // Web ile aynı yapı: posts/{postId}/likes/{userId}
            db.collection("posts").document(postId)
                .collection("likes").document(userId)
                .getDocument { snapshot, _ in
                    if snapshot?.exists == true { enriched[i].isLiked = true }
                    group.leave()
                }
        }

        group.notify(queue: .main) { completion(enriched) }
    }
}
