import SwiftUI

struct PostDetailView: View {
    @EnvironmentObject var authService: AuthService
    let post: Post
    var onLike: () -> Void

    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @State private var isLoadingComments = true
    @FocusState private var commentFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Gönderi kartı (beğenisiz, sadece içerik)
                PostCard(
                    post: post,
                    currentUserId: authService.firebaseUser?.uid ?? "",
                    onLike: onLike,
                    onComment: { commentFocused = true },
                    onUserTap: {}
                )
                .padding(.horizontal)
                .padding(.top)

                Divider().padding(.vertical, 8)

                // Yorumlar
                Text("Yorumlar")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                if isLoadingComments {
                    ProgressView().frame(maxWidth: .infinity).padding()
                } else if comments.isEmpty {
                    Text("Henüz yorum yok. İlk yorumu sen yap!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    ForEach(comments) { comment in
                        CommentRow(comment: comment)
                        Divider().padding(.leading, 56)
                    }
                }
            }
        }
        .navigationTitle("Gönderi")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            commentInput
        }
        .onAppear { loadComments() }
    }

    private var commentInput: some View {
        HStack(spacing: 10) {
            if let user = authService.socialUser {
                avatarView(emoji: user.avatarEmoji, color: user.profileColor.color, size: 32)
            }
            TextField("Yorum yaz...", text: $newComment)
                .focused($commentFocused)
                .textFieldStyle(.roundedBorder)

            Button {
                submitComment()
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(newComment.isEmpty ? .secondary : .blue)
            }
            .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    private func loadComments() {
        SocialService.shared.fetchComments(postId: post.id) { fetched in
            self.comments = fetched
            self.isLoadingComments = false
        }
    }

    private func submitComment() {
        guard let user = authService.socialUser,
              !newComment.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let text = newComment
        newComment = ""
        HapticManager.impact(.light)
        SocialService.shared.addComment(postId: post.id, text: text, user: user) { _ in
            loadComments()
        }
    }
}

private struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(comment.userAvatarEmoji)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(comment.userDisplayName)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(comment.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Text(comment.text)
                    .font(.subheadline)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
