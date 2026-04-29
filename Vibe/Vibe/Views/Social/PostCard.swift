import SwiftUI

struct PostCard: View {
    let post: Post
    let currentUserId: String
    var onLike: () -> Void
    var onComment: () -> Void
    var onUserTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Kullanıcı başlığı
            HStack(spacing: 10) {
                Button(action: onUserTap) {
                    avatarView(emoji: post.userAvatarEmoji, color: post.userProfileColor.color, size: 36)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Button(action: onUserTap) {
                        Text(post.userDisplayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                    HStack(spacing: 4) {
                        Text(post.emotion.emoji)
                        Text(post.emotion.displayName)
                            .foregroundColor(post.emotion.color)
                        Text("·")
                        Text(post.createdAt, style: .relative)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // Çizim görseli
            AsyncImage(url: URL(string: post.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .background(post.emotion.color.opacity(0.05))
                case .failure:
                    Rectangle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(height: 200)
                        .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                case .empty:
                    Rectangle()
                        .fill(Color(UIColor.secondarySystemBackground))
                        .frame(height: 200)
                        .overlay(ProgressView())
                @unknown default:
                    EmptyView()
                }
            }

            // Altta aksiyonlar
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 20) {
                    // Beğen
                    Button(action: onLike) {
                        HStack(spacing: 5) {
                            Image(systemName: post.isLiked ? "heart.fill" : "heart")
                                .foregroundColor(post.isLiked ? .red : .primary)
                                .symbolEffect(.bounce, value: post.isLiked)
                            Text("\(post.likeCount)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }

                    // Yorum
                    Button(action: onComment) {
                        HStack(spacing: 5) {
                            Image(systemName: "bubble.right")
                            Text("\(post.commentCount)")
                                .font(.subheadline)
                        }
                        .foregroundColor(.primary)
                    }

                    Spacer()
                }

                // Açıklama
                if !post.caption.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Text(post.userDisplayName)
                            .font(.subheadline.weight(.semibold))
                        Text(post.caption)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
