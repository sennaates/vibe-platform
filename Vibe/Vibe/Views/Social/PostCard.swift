import SwiftUI

struct PostCard: View {
    let post: Post
    let currentUserId: String
    var onLike: () -> Void
    var onComment: () -> Void
    var onUserTap: () -> Void
    var onDelete: (() -> Void)? = nil

    var isOwnPost: Bool { post.userId == currentUserId }

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

                if isOwnPost, let onDelete {
                    Menu {
                        Button(role: .destructive) {
                            HapticManager.notification(.warning)
                            onDelete()
                        } label: {
                            Label("Gönderiyi Sil", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(10)
                            .contentShape(Rectangle())
                    }
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
            HStack(spacing: 18) {
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
                .padding(.vertical, 5)
                .background(post.emotion.color.opacity(0.10))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // ── Açıklama ───────────────────────────────────────
            if !post.caption.isEmpty {
                HStack(alignment: .top, spacing: 5) {
                    Text(post.userDisplayName)
                        .font(.subheadline.weight(.semibold))
                    Text(post.caption)
                        .font(.subheadline)
                        .foregroundColor(.primary.opacity(0.85))
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
    }

    // MARK: - Beğeni butonu

    private var likeButton: some View {
        Button(action: onLike) {
            HStack(spacing: 5) {
                Image(systemName: post.isLiked ? "heart.fill" : "heart")
                    .foregroundColor(post.isLiked ? .red : .secondary)
                    .symbolEffect(.bounce, value: post.isLiked)
                    .font(.system(size: 18))
                Text("\(post.likeCount)")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(post.isLiked ? .red : .secondary)
                    .monospacedDigit()
            }
            .contentShape(Rectangle())
        }
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
            .contentShape(Rectangle())
        }
    }
}
