import SwiftUI

struct SearchView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var query       = ""
    @State private var results     = [SocialUser]()
    @State private var isSearching = false
    @State private var followingIds = Set<String>()
    @State private var followLoading = Set<String>()

    private let social = SocialService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Arama çubuğu
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColor.inkMuted)

                    TextField("Kullanıcı ara...", text: $query)
                        .font(.system(size: 16))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.search)
                        .onSubmit { runSearch() }
                        .onChange(of: query) { _, new in
                            if new.isEmpty { results = [] }
                            else { runSearch() }
                        }

                    if isSearching {
                        ProgressView().scaleEffect(0.8)
                    } else if !query.isEmpty {
                        Button { query = ""; results = [] } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColor.inkMuted)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .strokeBorder(AppColor.divider, lineWidth: 0.5)
                )
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)

                Divider().overlay(AppColor.divider)

                // Sonuçlar
                if results.isEmpty && query.isEmpty {
                    EmptyStateView(
                        icon: "person.2.magnifyingglass",
                        title: "Kullanıcı Bul",
                        message: "İsim yazarak arkadaşlarını ara ve takip et"
                    )
                    .padding(.top, 40)
                    Spacer()
                } else if results.isEmpty && !query.isEmpty && !isSearching {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "Sonuç bulunamadı",
                        message: "\"\(query)\" için kimse bulunamadı"
                    )
                    .padding(.top, 40)
                    Spacer()
                } else {
                    List(results) { user in
                        NavigationLink(destination:
                            PublicProfileView(userId: user.id)
                                .environmentObject(authService)
                        ) {
                            UserRow(
                                user: user,
                                isFollowing: followingIds.contains(user.id),
                                isLoading: followLoading.contains(user.id),
                                isOwn: user.id == authService.firebaseUser?.uid,
                                onFollow: { toggleFollow(user) }
                            )
                        }
                        .listRowBackground(AppColor.canvas)
                        .listRowInsets(EdgeInsets(top: 6, leading: sizeClass == .regular ? 32 : 20, bottom: 6, trailing: sizeClass == .regular ? 32 : 20))
                    }
                    .listStyle(.plain)
                    .background(AppColor.canvas)
                }
            }
            .background(AppColor.canvas)
            .navigationTitle("Ara")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { loadFollowingIds() }
        }
    }

    private func runSearch() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        social.searchUsers(query: query) { users in
            withAnimation(.easeInOut(duration: 0.2)) {
                results = users
            }
            isSearching = false
        }
    }

    private func loadFollowingIds() {
        guard let uid = authService.firebaseUser?.uid else { return }
        social.fetchFollowingIds(userId: uid) { ids in
            followingIds = Set(ids)
        }
    }

    private func toggleFollow(_ user: SocialUser) {
        guard let currentUid = authService.firebaseUser?.uid else { return }
        followLoading.insert(user.id)

        if followingIds.contains(user.id) {
            social.unfollow(targetUserId: user.id, currentUserId: currentUid) { _ in
                followingIds.remove(user.id)
                followLoading.remove(user.id)
            }
        } else {
            social.follow(targetUserId: user.id, currentUserId: currentUid) { _ in
                followingIds.insert(user.id)
                followLoading.remove(user.id)
            }
        }
    }
}

// MARK: - UserRow

private struct UserRow: View {
    let user: SocialUser
    let isFollowing: Bool
    let isLoading: Bool
    let isOwn: Bool
    let onFollow: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(user.profileColor.color.opacity(0.18))
                    .frame(width: 46, height: 46)
                Text(user.avatarEmoji)
                    .font(.system(size: 22))
            }

            // İsim + istatistik
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                Text("\(user.postCount) çizim · \(user.followerCount) takipçi")
                    .font(.system(size: 12))
                    .foregroundColor(AppColor.inkMuted)
            }

            Spacer()

            // Takip butonu (kendi profili değilse)
            if !isOwn {
                Button(action: onFollow) {
                    if isLoading {
                        ProgressView().scaleEffect(0.75)
                            .frame(width: 80, height: 30)
                    } else if isFollowing {
                        Text("Takipte")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.inkMuted)
                            .frame(width: 88, height: 36)
                            .background(AppColor.surfaceMuted)
                            .clipShape(Capsule())
                    } else {
                        Text("Takip Et")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 88, height: 36)
                            .background(AppColor.accent)
                            .clipShape(Capsule())
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
