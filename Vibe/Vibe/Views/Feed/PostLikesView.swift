import SwiftUI
import FirebaseFirestore

struct LikeItem: Identifiable {
    let id: String // userId
    let userName: String
    let userAvatar: String
    let userColor: String
    let createdAt: Date
}

struct PostLikesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    let postId: String
    
    @State private var likes: [LikeItem] = []
    @State private var isLoading = true
    @State private var userNavTag: UserNavItem? = nil
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().tint(AppColor.accent)
                } else if likes.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("Henüz kimse beğenmemiş")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(likes) { like in
                            HStack(spacing: 12) {
                                let profileColor = ProfileColor(rawValue: like.userColor) ?? .blue
                                avatarView(emoji: like.userAvatar, color: profileColor.color, size: 40)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(like.userName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(AppColor.ink)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                userNavTag = UserNavItem(userId: like.id)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Beğenenler")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $userNavTag) { item in
                PublicProfileView(userId: item.userId)
                    .environmentObject(authService)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                }
            }
            .onAppear { loadLikes() }
        }
    }
    
    private func loadLikes() {
        Firestore.firestore()
            .collection("posts").document(postId).collection("likes")
            .order(by: "createdAt", descending: true)
            .getDocuments { snap, _ in
                let fetched = snap?.documents.compactMap { doc -> LikeItem? in
                    let data = doc.data()
                    let userName = data["userName"] as? String ?? "Kullanıcı"
                    let userAvatar = data["userAvatar"] as? String ?? "👤"
                    let userColor = data["userColor"] as? String ?? "blue"
                    let ts = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    return LikeItem(id: doc.documentID, userName: userName, userAvatar: userAvatar, userColor: userColor, createdAt: ts)
                } ?? []
                
                self.likes = fetched
                self.isLoading = false
                
                // Beğeni sayısını senkronize et
                let actualCount = fetched.count
                let postRef = Firestore.firestore().collection("posts").document(self.postId)
                postRef.getDocument { docSnap, _ in
                    guard let docSnap = docSnap, docSnap.exists, let data = docSnap.data() else { return }
                    let currentLikeCount = data["likeCount"] as? Int ?? 0
                    let currentLikesCount = data["likesCount"] as? Int ?? 0
                    if currentLikeCount != actualCount || currentLikesCount != actualCount {
                        postRef.updateData([
                            "likeCount": actualCount,
                            "likesCount": actualCount
                        ])
                    }
                }
            }
    }
}
