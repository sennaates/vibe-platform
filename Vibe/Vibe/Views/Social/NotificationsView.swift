import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var notifications = [AppNotification]()
    @State private var listener: (any ListenerRegistration)?
    @State private var loading = true

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
                    List {
                        ForEach(notifications) { notif in
                            NotifRow(notif: notif)
                                .listRowBackground(
                                    notif.read ? AppColor.canvas : AppColor.accent.opacity(0.06)
                                )
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                    .background(AppColor.canvas)
                }
            }
            .background(AppColor.canvas)
            .navigationTitle("Bildirimler")
            .navigationBarTitleDisplayMode(.inline)
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
}

// MARK: - NotifRow

private struct NotifRow: View {
    let notif: AppNotification

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
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
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
