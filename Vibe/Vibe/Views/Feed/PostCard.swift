import SwiftUI

struct PostCard: View {
    let post: Post
    let currentUserId: String
    var onLike: () -> Void
    var onComment: () -> Void
    var onUserTap: () -> Void
    var onDelete: (() -> Void)? = nil
    var onReport: (() -> Void)? = nil
    var onHashtagTap: ((String) -> Void)? = nil
    var onLikesTap: (() -> Void)? = nil

    @State private var isLiking = false
    @State private var showLikesSheet = false
    @State private var isLiked: Bool
    @State private var likeCount: Int

    var isOwnPost: Bool { post.userId == currentUserId }

    init(
        post: Post,
        currentUserId: String,
        onLike: @escaping () -> Void,
        onComment: @escaping () -> Void,
        onUserTap: @escaping () -> Void,
        onDelete: (() -> Void)? = nil,
        onReport: (() -> Void)? = nil,
        onHashtagTap: ((String) -> Void)? = nil,
        onLikesTap: (() -> Void)? = nil
    ) {
        self.post = post
        self.currentUserId = currentUserId
        self.onLike = onLike
        self.onComment = onComment
        self.onUserTap = onUserTap
        self.onDelete = onDelete
        self.onReport = onReport
        self.onHashtagTap = onHashtagTap
        self.onLikesTap = onLikesTap
        
        self._isLiked = State(initialValue: post.isLiked)
        self._likeCount = State(initialValue: post.likeCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Kullanıcı başlığı ──────────────────────────────
            HStack(spacing: 10) {
                Button(action: onUserTap) {
                    avatarView(emoji: post.userAvatarEmoji,
                               color: post.userProfileColor.color, size: 38)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Button(action: onUserTap) {
                        Text(post.userDisplayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                    HStack(spacing: 5) {
                        Text(post.emotion.emoji)
                            .font(.caption)
                        Text(post.emotion.displayName)
                            .font(.caption.weight(.medium))
                            .foregroundColor(post.emotion.color)
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(post.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Menu {
                    if isOwnPost, let onDelete {
                        Button(role: .destructive) {
                            HapticManager.notification(.warning)
                            onDelete()
                        } label: {
                            Label("Gönderiyi Sil", systemImage: "trash")
                        }
                    } else if let onReport {
                        Button {
                            HapticManager.impact(.light)
                            onReport()
                        } label: {
                            Label("Şikayet Et", systemImage: "flag")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(10)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // ── Çizim görseli ──────────────────────────────────
            AsyncImage(url: URL(string: post.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .background(post.emotion.color.opacity(0.04))
                case .failure:
                    Rectangle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(height: 220)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary.opacity(0.4))
                                Text("Görsel yüklenemedi")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                case .empty:
                    Rectangle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(height: 220)
                        .overlay(
                            ProgressView()
                                .tint(post.emotion.color)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .clipShape(Rectangle())

            // ── Beğeni + Yorum ─────────────────────────────────
            HStack(spacing: 4) {
                likeButton
                commentButton
                Spacer()

                // Duygu etiketi
                HStack(spacing: 4) {
                    Text(post.emotion.emoji)
                    Text(post.emotion.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(post.emotion.color)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(post.emotion.color.opacity(0.10))
                .clipShape(Capsule())
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)

            // ── Açıklama ───────────────────────────────────────
            if !post.caption.isEmpty {
                HStack(alignment: .top, spacing: 5) {
                    Text(post.userDisplayName)
                        .font(.subheadline.weight(.semibold))
                    CaptionText(text: post.caption, onHashtagTap: onHashtagTap)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            } else {
                Spacer().frame(height: 4)
            }
        }
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 3)
        .sheet(isPresented: $showLikesSheet) {
            PostLikesView(postId: post.id)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: post.isLiked) { _, newValue in
            isLiked = newValue
        }
        .onChange(of: post.likeCount) { _, newValue in
            likeCount = newValue
        }
    }

    // MARK: - Beğeni butonu

    private var likeButton: some View {
        HStack(spacing: 5) {
            Button {
                guard !isLiking else { return }
                isLiking = true
                
                // Optimistic UI updates
                if isLiked {
                    isLiked = false
                    likeCount -= 1
                } else {
                    isLiked = true
                    likeCount += 1
                }
                
                onLike()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    isLiking = false
                }
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundColor(isLiked ? .red : .secondary)
                    .symbolEffect(.bounce, value: isLiked)
                    .font(.system(size: 18))
                    .padding(.vertical, AppSpacing.sm)
                    .padding(.leading, AppSpacing.sm)
            }
            .buttonStyle(.plain)
            
            Button {
                onLikesTap?() ?? { showLikesSheet = true }()
            } label: {
                Text("\(likeCount)")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isLiked ? .red : .secondary)
                    .monospacedDigit()
                    .padding(.vertical, AppSpacing.sm)
                    .padding(.trailing, AppSpacing.sm)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
    }

    // MARK: - Yorum butonu

    private var commentButton: some View {
        Button(action: onComment) {
            HStack(spacing: 5) {
                Image(systemName: "bubble.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                Text("\(post.commentCount)")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.sm)
            .contentShape(Rectangle())
        }
    }
}
