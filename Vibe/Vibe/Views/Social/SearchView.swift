import SwiftUI

struct SearchView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var query            = ""
    @State private var results          = [SocialUser]()
    @State private var isSearching      = false
    @State private var followingIds     = Set<String>()
    @State private var followLoading    = Set<String>()
    @State private var trendingTags     = [(tag: String, count: Int)]()
    @State private var hashtagNavTag    : HashtagNavItem? = nil

    private let social = SocialService.shared

    // True when query begins with #
    private var isHashtagSearch: Bool {
        query.hasPrefix("#") && query.count > 1
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── Arama çubuğu ────────────────────────────────
                HStack(spacing: 10) {
                    Image(systemName: isHashtagSearch ? "number" : "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isHashtagSearch ? AppColor.accent : AppColor.inkMuted)

                    TextField("Kullanıcı veya #hashtag ara...", text: $query)
                        .font(.system(size: 16))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.search)
                        .onSubmit { handleSubmit() }
                        .onChange(of: query) { _, new in
                            if new.isEmpty {
                                results = []
                            } else if !new.hasPrefix("#") {
                                runSearch()
                            }
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
                        .strokeBorder(
                            isHashtagSearch ? AppColor.accent.opacity(0.4) : AppColor.divider,
                            lineWidth: isHashtagSearch ? 1 : 0.5
                        )
                )
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .animation(.easeInOut(duration: 0.15), value: isHashtagSearch)

                Divider().overlay(AppColor.divider)

                // ── İçerik ──────────────────────────────────────
                if isHashtagSearch {
                    // Hashtag arama ipucu
                    hashtagSearchHint

                } else if query.isEmpty {
                    // Boş durum: trend hashtagler + açıklama
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppSpacing.xl) {
                            if !trendingTags.isEmpty {
                                trendingHashtagsSection
                            }
                            EmptyStateView(
                                icon: "person.2.magnifyingglass",
                                title: "Kullanıcı Bul",
                                message: "İsim yazarak arkadaşlarını ara, ya da #hashtag ile gönderi bul"
                            )
                        }
                        .padding(.top, AppSpacing.lg)
                    }

                } else if results.isEmpty && !isSearching {
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
                        .listRowInsets(EdgeInsets(
                            top: 6,
                            leading: sizeClass == .regular ? 32 : 20,
                            bottom: 6,
                            trailing: sizeClass == .regular ? 32 : 20
                        ))
                    }
                    .listStyle(.plain)
                    .background(AppColor.canvas)
                }
            }
            .background(AppColor.canvas)
            .navigationTitle("Ara")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $hashtagNavTag) { item in
                HashtagFeedView(tag: item.tag)
                    .environmentObject(authService)
            }
            .onAppear {
                loadFollowingIds()
                loadTrendingHashtags()
            }
        }
    }

    // MARK: - Hashtag ipucu satırı

    private var hashtagSearchHint: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer().frame(height: AppSpacing.xl)
            VStack(spacing: 12) {
                Text("#")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(AppColor.accent)
                Text("\(query.dropFirst()) ile ara")
                    .font(.headline)
                    .foregroundColor(AppColor.ink)
                Text("Bu hashtag'e ait gönderileri görmek için ara tuşuna bas")
                    .font(.subheadline)
                    .foregroundColor(AppColor.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }
            Button {
                handleSubmit()
            } label: {
                Text("\(query) ara")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.xxl)
                    .padding(.vertical, 12)
                    .background(AppColor.accent)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    // MARK: - Trend hashtagler

    private var trendingHashtagsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColor.accent)
                Text("TREND HASHTAGLER")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColor.inkMuted)
                    .kerning(0.8)
            }
            .padding(.horizontal, AppSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(trendingTags, id: \.tag) { item in
                        Button {
                            HapticManager.impact(.light)
                            hashtagNavTag = HashtagNavItem(tag: item.tag)
                        } label: {
                            HStack(spacing: 4) {
                                Text("#")
                                    .font(.system(size: 13, weight: .bold))
                                Text(item.tag)
                                    .font(.system(size: 13, weight: .semibold))
                                Text("\(item.count)")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppColor.accent.opacity(0.6))
                            }
                            .foregroundColor(AppColor.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(AppColor.accent.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
            }
        }
    }

    // MARK: - Aksiyon

    private func handleSubmit() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("#") && trimmed.count > 1 {
            let tag = String(trimmed.dropFirst()).lowercased()
            hashtagNavTag = HashtagNavItem(tag: tag)
        } else {
            runSearch()
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

    private func loadTrendingHashtags() {
        social.fetchTrendingHashtags { tags in
            withAnimation {
                trendingTags = tags
            }
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
            ZStack {
                Circle()
                    .fill(user.profileColor.color.opacity(0.18))
                    .frame(width: 46, height: 46)
                Text(user.avatarEmoji)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                Text("\(user.postCount) çizim · \(user.followerCount) takipçi")
                    .font(.system(size: 12))
                    .foregroundColor(AppColor.inkMuted)
            }

            Spacer()

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
