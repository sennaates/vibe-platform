import SwiftUI
import FirebaseFirestore

enum FollowsListMode {
    case followers
    case following
    
    var title: String {
        switch self {
        case .followers:
            return "Takipçiler"
        case .following:
            return "Takip Edilenler"
        }
    }
    
    var emptyText: String {
        switch self {
        case .followers:
            return "Henüz takipçi yok"
        case .following:
            return "Henüz kimse takip edilmiyor"
        }
    }
}

struct FollowsListView: View {
    @EnvironmentObject var authService: AuthService
    let userId: String
    let mode: FollowsListMode
    
    @State private var users: [SocialUser] = []
    @State private var isLoading = true
    @State private var selectedUserId: UserNavItem? = nil
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(AppColor.accent)
                        .scaleEffect(1.2)
                    Spacer()
                }
            } else if users.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 44))
                        .foregroundColor(AppColor.inkMuted.opacity(0.4))
                    Text(mode.emptyText)
                        .font(.subheadline)
                        .foregroundColor(AppColor.inkMuted)
                    Spacer()
                }
            } else {
                List {
                    ForEach(users) { user in
                        HStack(spacing: 12) {
                            avatarView(emoji: user.avatarEmoji, color: user.profileColor.color, size: 44)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(AppColor.ink)
                                
                                Text("\(user.postCount) çizim")
                                    .font(.caption)
                                    .foregroundColor(AppColor.inkMuted)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColor.inkSubtle)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticManager.impact(.light)
                            selectedUserId = UserNavItem(userId: user.id)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(AppColor.canvas)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(AppColor.canvas.ignoresSafeArea())
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedUserId) { item in
            PublicProfileView(userId: item.userId)
                .environmentObject(authService)
        }
        .onAppear {
            loadUsers()
        }
    }
    
    private func loadUsers() {
        let completion: ([String]) -> Void = { ids in
            SocialService.shared.fetchUsers(userIds: ids) { fetchedUsers in
                self.users = fetchedUsers
                self.isLoading = false
            }
        }
        
        if mode == .followers {
            SocialService.shared.fetchFollowerIds(userId: userId, completion: completion)
        } else {
            SocialService.shared.fetchFollowingIds(userId: userId, completion: completion)
        }
    }
}
