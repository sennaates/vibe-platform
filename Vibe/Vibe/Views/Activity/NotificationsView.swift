import SwiftUI
import FirebaseFirestore

struct NotificationsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var notifications = [AppNotification]()
    @State private var listener: (any ListenerRegistration)?
    @State private var loading = true

    @State private var userNavTag: UserNavItem? = nil
    @State private var selectedPost: Post? = nil
    @State private var isLoadingPost = false

    private let social = SocialService.shared

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if notifications.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "Henüz bildirim yok",
                        message: "Biri seni takip ettiğinde veya çizimini beğendiğinde burada görünecek"
                    )
                } else {
                    ZStack {
                        List {
                            ForEach(notifications) { notif in
                                NotifRow(
                                    notif: notif,
                                    onUserTap: {
                                        userNavTag = UserNavItem(userId: notif.fromUserId)
                                    },
                                    onPostTap: {
                                        if let postId = notif.postId {
                                            navigateToPost(postId: postId)
                                        }
                                    }
                                )
                                .listRowBackground(
                                    notif.read ? AppColor.canvas : AppColor.accent.opacity(0.06)
                                )
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                            }
                        }
                        .listStyle(.plain)
                        .background(AppColor.canvas)

                        if isLoadingPost {
                            Color.black.opacity(0.15)
                                .ignoresSafeArea()
                            ProgressView()
                                .tint(AppColor.accent)
                                .padding(20)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                        }
                    }
                }
            }
            .background(AppColor.canvas)
            .navigationTitle("Bildirimler")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $userNavTag) { item in
                PublicProfileView(userId: item.userId)
                    .environmentObject(authService)
            }
            .navigationDestination(item: $selectedPost) { post in
                PostDetailView(post: post, onLike: {
                    guard let user = authService.socialUser else { return }
                    SocialService.shared.toggleLike(post: post, user: user) { _ in }
                })
                .environmentObject(authService)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !notifications.isEmpty {
                        Button("Tümünü Oku") {
                            markAllRead()
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColor.accent)
                    }
                }
            }
        }
        .onAppear {
            guard let uid = authService.firebaseUser?.uid else { return }
            listener = social.listenNotifications(userId: uid) { notifs in
                withAnimation(.easeInOut(duration: 0.2)) {
                    notifications = notifs
                    loading = false
                }
            }
            // Kısa gecikme sonrası okundu işaretle
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                markAllRead()
            }
        }
        .onDisappear {
            listener?.remove()
            listener = nil
        }
    }

    private func markAllRead() {
        guard let uid = authService.firebaseUser?.uid else { return }
        social.markAllNotificationsRead(userId: uid)
        // Yerel güncelleme
        for i in notifications.indices { notifications[i].read = true }
    }

    private func navigateToPost(postId: String) {
        guard let currentUid = authService.firebaseUser?.uid else { return }
        isLoadingPost = true
        FeedService.shared.fetchPost(postId: postId, currentUserId: currentUid) { post in
            isLoadingPost = false
            if let post {
                selectedPost = post
            }
        }
    }
}

// MARK: - NotifRow

private struct NotifRow: View {
    let notif: AppNotification
    let onUserTap: () -> Void
    let onPostTap: () -> Void

    private var icon: (name: String, color: Color) {
        switch notif.type {
        case "like":    return ("heart.fill", .red)
        case "comment": return ("bubble.left.fill", AppColor.accent)
        default:        return ("person.fill.badge.plus", .blue)
        }
    }

    private var body2: String {
        switch notif.type {
        case "like":    return "çizimini beğendi"
        case "comment": return "çizimini yorumladı"
        default:        return "seni takip etmeye başladı"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar + ikon rozeti
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(AppColor.surfaceMuted)
                        .frame(width: 46, height: 46)
                    Text(notif.fromUserAvatar)
                        .font(.system(size: 22))
                }

                ZStack {
                    Circle()
                        .fill(icon.color)
                        .frame(width: 18, height: 18)
                    Image(systemName: icon.name)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white)
                }
                .offset(x: 4, y: 4)
            }
            .contentShape(Circle())
            .onTapGesture {
                onUserTap()
            }

            // Metin
            VStack(alignment: .leading, spacing: 3) {
                Group {
                    Text(notif.fromUserName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColor.ink)
                    + Text(" \(body2)")
                        .font(.system(size: 14))
                        .foregroundColor(AppColor.inkMuted)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if notif.type == "follow" {
                        onUserTap()
                    } else {
                        onPostTap()
                    }
                }

                Text(relativeTime(notif.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(AppColor.inkMuted.opacity(0.7))
            }

            Spacer()

            // Post thumbnail (like / comment)
            if let imgUrl = notif.postImageUrl, !imgUrl.isEmpty {
                AsyncImage(url: URL(string: imgUrl)) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        AppColor.surfaceMuted
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                .contentShape(Rectangle())
                .onTapGesture {
                    onPostTap()
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func relativeTime(_ date: Date) -> String {
        let diff = Int(Date().timeIntervalSince(date))
        if diff < 60         { return "şimdi" }
        if diff < 3600       { return "\(diff / 60) dk" }
        if diff < 86400      { return "\(diff / 3600) sa" }
        return "\(diff / 86400) gün"
    }
}
