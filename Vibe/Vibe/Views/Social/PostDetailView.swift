import SwiftUI
import FirebaseFirestore

struct PostDetailView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    let post: Post
    var onLike: () -> Void
    var onDelete: (() -> Void)? = nil

    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @State private var isLoadingComments = true
    @State private var commentListener: ListenerRegistration? = nil
    @State private var hashtagNavTag: HashtagNavItem? = nil
    @FocusState private var commentFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Gönderi kartı
                PostCard(
                    post: post,
                    currentUserId: authService.firebaseUser?.uid ?? "",
                    onLike: onLike,
                    onComment: { commentFocused = true },
                    onUserTap: {},
                    onDelete: onDelete.map { del in { del(); dismiss() } },
                    onHashtagTap: { tag in hashtagNavTag = HashtagNavItem(tag: tag) }
                )
                .navigationDestination(item: $hashtagNavTag) { item in
                    HashtagFeedView(tag: item.tag)
                        .environmentObject(authService)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)

                // Yorumlar başlığı
                HStack(alignment: .firstTextBaseline) {
                    Text("Yorumlar")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColor.ink)
                    if !comments.isEmpty {
                        Text("\(comments.count)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColor.inkMuted)
                    }
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.sm)

                // Yorum içeriği
                if isLoadingComments {
                    HStack {
                        Spacer()
                        ProgressView().tint(AppColor.accent)
                        Spacer()
                    }
                    .padding(.vertical, AppSpacing.xl)
                } else if comments.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(AppColor.inkMuted.opacity(0.5))
                        Text("Henüz yorum yok")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColor.inkMuted)
                        Text("İlk yorumu sen yap")
                            .font(.system(size: 12))
                            .foregroundColor(AppColor.inkMuted.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
                } else {
                    VStack(spacing: 0) {
                        ForEach(comments) { comment in
                            CommentRow(comment: comment)
                            if comment.id != comments.last?.id {
                                Divider()
                                    .background(AppColor.divider)
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .strokeBorder(AppColor.divider, lineWidth: 0.5)
                    )
                    .padding(.horizontal, AppSpacing.md)
                }

                Spacer(minLength: 80)
            }
        }
        .background(AppColor.canvas.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Gönderi")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            commentInput
        }
        .onAppear { startListening() }
        .onDisappear { stopListening() }
    }

    // MARK: - Yorum Girişi

    private var commentInput: some View {
        HStack(spacing: 10) {
            if let user = authService.socialUser {
                avatarView(emoji: user.avatarEmoji, color: user.profileColor.color, size: 34)
            }

            TextField("Yorum yaz...", text: $newComment, axis: .vertical)
                .focused($commentFocused)
                .font(.system(size: 15))
                .lineLimit(1...4)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm + 2)
                .background(AppColor.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(
                        commentFocused ? AppColor.accent.opacity(0.40) : AppColor.divider,
                        lineWidth: commentFocused ? 1.5 : 0.5
                    )
                )
                .animation(.easeInOut(duration: 0.2), value: commentFocused)

            Button(action: submitComment) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(
                        newComment.trimmingCharacters(in: .whitespaces).isEmpty
                        ? AppColor.inkMuted.opacity(0.4)
                        : AppColor.accent
                    )
            }
            .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
        .padding(.bottom, AppSpacing.xs)
        .background(
            AppColor.canvas
                .overlay(
                    Rectangle().fill(AppColor.divider).frame(height: 0.5),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func startListening() {
        commentListener?.remove()
        commentListener = SocialService.shared.listenComments(postId: post.id) { fetched in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.comments = fetched
                self.isLoadingComments = false
            }
        }
    }

    private func stopListening() {
        commentListener?.remove()
        commentListener = nil
    }

    private func submitComment() {
        guard let user = authService.socialUser,
              !newComment.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let text = newComment
        newComment = ""
        HapticManager.impact(.light)
        // Listener otomatik güncelleyecek, manuel reload gerekmiyor
        SocialService.shared.addComment(postId: post.id, text: text, user: user) { _ in }
    }
}

// MARK: - Yorum Satırı

private struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(comment.userAvatarEmoji)
                .font(.system(size: 18))
                .frame(width: 38, height: 38)
                .background(AppColor.surfaceMuted)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(comment.userDisplayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColor.ink)
                    Text("·")
                        .foregroundColor(AppColor.inkMuted)
                    Text(comment.createdAt, style: .relative)
                        .font(.system(size: 11))
                        .foregroundColor(AppColor.inkMuted)
                    Spacer()
                }
                Text(comment.text)
                    .font(.system(size: 14))
                    .foregroundColor(AppColor.ink)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 12)
    }
}
