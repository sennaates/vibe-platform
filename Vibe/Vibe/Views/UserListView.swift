import SwiftUI

struct UserListView: View {
    @StateObject private var userStore = UserStore.shared
    @State private var isShowingCreateForm = false
    @State private var editingUser: UserProfile? = nil
    @State private var selectedUser: UserProfile? = nil

    var body: some View {
        NavigationStack {
            Group {
                if userStore.users.isEmpty {
                    emptyState
                } else {
                    userGrid
                }
            }
            .navigationTitle("Vibe")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingCreateForm = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $isShowingCreateForm) {
                UserFormView(mode: .create) { newUser in
                    userStore.add(newUser)
                }
            }
            .sheet(item: $editingUser) { user in
                UserFormView(mode: .edit(user)) { updated in
                    userStore.update(updated)
                }
            }
            .fullScreenCover(item: $selectedUser) { user in
                CanvasView(user: user)
            }
        }
    }

    // MARK: - Grid

    private var userGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)], spacing: 16) {
                ForEach(userStore.users) { user in
                    UserCard(user: user)
                        .onTapGesture { selectedUser = user }
                        .contextMenu {
                            Button {
                                editingUser = user
                            } label: {
                                Label("Düzenle", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                userStore.delete(user)
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                }

                // Yeni ekle butonu
                Button { isShowingCreateForm = true } label: {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(width: 70, height: 70)
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                        Text("Yeni Ekle")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.secondary.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .foregroundColor(.secondary.opacity(0.3))
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Henüz kullanıcı yok")
                .font(.title2.weight(.semibold))

            Text("İlk kullanıcını oluşturmak için aşağıdaki butona dokun.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                isShowingCreateForm = true
            } label: {
                Label("Kullanıcı Oluştur", systemImage: "person.badge.plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Kullanıcı Kartı

private struct UserCard: View {
    let user: UserProfile

    var body: some View {
        VStack(spacing: 12) {
            avatarView(emoji: user.avatarEmoji, color: user.profileColor.color, size: 70)

            Text(user.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Text(user.createdAt, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(user.profileColor.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(user.profileColor.color.opacity(0.2), lineWidth: 1.5)
        )
    }
}
