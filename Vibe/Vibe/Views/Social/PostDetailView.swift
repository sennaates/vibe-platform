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

    // Yorum yanıtlama
    @State private var replyTo: Comment? = nil

    // Caption düzenleme (kendi postu ise)
    @State private var isEditingCaption = false
    @State private var captionDraft = ""
    @State private var isSavingCaption = false

    @FocusState private var commentFocused: Bool

    private var isOwnPost: Bool {
        post.userId == authService.firebaseUser?.uid
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── Gönderi kartı ──────────────────────────────
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

                // ── Caption düzenleme (kendi postu) ───────────
                if isOwnPost {
                    if isEditingCaption {
                        captionEditSection
                    } else {
                        Button {
                            captionDraft = post.caption
                            withAnimation { isEditingCaption = true }
                            commentFocused = false
                        } label: {
                            HStack {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11))
                                Text("Açıklamayı Düzenle")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(AppColor.inkMuted)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.top, AppSpacing.xs)
                        }
                    }
                }

                // ── Yorumlar başlığı ───────────────────────────
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

                // ── Yorum içeriği ──────────────────────────────
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
                            CommentRow(
                                comment: comment,
                                isOwn: comment.userId == authService.firebaseUser?.uid,
                                onReply: {
                                    replyTo = comment
                                    commentFocused = true
                                },
                                onDelete: (comment.userId == authService.firebaseUser?.uid || isOwnPost)
                                    ? { deleteComment(comment) }
                                    : nil
                            )
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

                Spacer(minLength: 100)
            }
        }
        .background(AppColor.canvas.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Gönderi")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            commentInputArea
        }
        .onAppear { startListening() }
        .onDisappear { stopListening() }
    }

    // MARK: - Caption Düzenleme Bölümü

    private var captionEditSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            TextField("Açıklama ekle… #hashtag kullanabilirsin", text: $captionDraft, axis: .vertical)
                .font(.system(size: 14))
                .lineLimit(1...6)
                .padding(AppSpacing.md)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .strokeBorder(AppColor.accent.opacity(0.35), lineWidth: 1)
                )

            HStack(spacing: AppSpacing.sm) {
                Spacer()
                Button("İptal") {
                    withAnimation { isEditingCaption = false }
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColor.inkMuted)

                Button {
                    saveCaption()
                } label: {
                    if isSavingCaption {
                        ProgressView().scaleEffect(0.7)
                            .frame(width: 60, height: 28)
                    } else {
                        Text("Kaydet")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, 7)
                            .background(AppColor.accent)
                            .clipShape(Capsule())
                    }
                }
                .disabled(isSavingCaption)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Yorum Giriş Alanı

    private var commentInputArea: some View {
        VStack(spacing: 0) {
            // Yanıtlıyorsun banner
            if let reply = replyTo {
                HStack {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.system(size: 11))
                        .foregroundColor(AppColor.accent)
                    Text("\(reply.userDisplayName)'e yanıt veriyorsun")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColor.accent)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3)) { replyTo = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppColor.inkMuted)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 8)
                .background(AppColor.accent.opacity(0.08))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // Giriş satırı
            HStack(spacing: 10) {
                if let user = authService.socialUser {
                    avatarView(emoji: user.avatarEmoji, color: user.profileColor.color, size: 34)
                }

                TextField(replyTo != nil ? "Yanıt yaz..." : "Yorum yaz...", text: $newComment, axis: .vertical)
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
        }
        .background(
            AppColor.canvas
                .overlay(
                    Rectangle().fill(AppColor.divider).frame(height: 0.5),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: replyTo?.id)
    }

    // MARK: - Aksiyonlar

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
        let reply = replyTo
        newComment = ""
        withAnimation { replyTo = nil }
        HapticManager.impact(.light)
        SocialService.shared.addComment(
            postId: post.id,
            text: text,
            user: user,
            replyToId: reply?.id,
            replyToName: reply?.userDisplayName
        ) { _ in }
    }

    private func deleteComment(_ comment: Comment) {
        SocialService.shared.deleteComment(postId: post.id, commentId: comment.id) { _ in }
    }

    private func saveCaption() {
        let trimmed = captionDraft.trimmingCharacters(in: .whitespaces)
        isSavingCaption = true
        // Extract tags
        let pattern = #"#([\wÀ-ɏЀ-ӿ]+)"#
        var tags: [String] = []
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(trimmed.startIndex..., in: trimmed)
            tags = regex.matches(in: trimmed, range: range).compactMap { match in
                guard let r = Range(match.range(at: 1), in: trimmed) else { return nil }
                return String(trimmed[r]).lowercased()
            }
        }
        var data: [String: Any] = ["caption": trimmed, "tags": tags]
        Firestore.firestore().collection("posts").document(post.id).updateData(data) { _ in
            isSavingCaption = false
            withAnimation { isEditingCaption = false }
        }
    }
}

// MARK: - Yorum Satırı

private struct CommentRow: View {
    let comment: Comment
    let isOwn: Bool
    var onReply: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @State private var showActions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Yanıtlanıyor ise indent ve referans
            if let replyName = comment.replyToName {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(AppColor.accent.opacity(0.3))
                        .frame(width: 2)
                        .frame(height: 14)
                    Text("@\(replyName)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppColor.accent)
                }
                .padding(.leading, 60)
                .padding(.bottom, 3)
            }

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

                        // Yanıtla / Sil
                        if showActions {
                            HStack(spacing: 8) {
                                if let onReply {
                                    Button {
                                        onReply()
                                        showActions = false
                                    } label: {
                                        Text("Yanıtla")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(AppColor.accent)
                                    }
                                }
                                if let onDelete {
                                    Button {
                                        onDelete()
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.system(size: 11))
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        }
                    }

                    Text(comment.text)
                        .font(.system(size: 14))
                        .foregroundColor(AppColor.ink)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                showActions.toggle()
            }
        }
    }
}
