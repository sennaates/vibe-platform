import SwiftUI

// MARK: - Kanvas Ön Ayarı

private struct CanvasPreset: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let color: ProfileColor
    let description: String
}

private let canvasPresets: [CanvasPreset] = [
    CanvasPreset(name: "Boş Kanvas", emoji: "🎨", color: .blue,
                 description: "Serbest"),
    CanvasPreset(name: "Duygu Günlüğü", emoji: "📓", color: .purple,
                 description: "Keşfet"),
    CanvasPreset(name: "Hızlı Eskiz", emoji: "⚡", color: .orange,
                 description: "Hızlı"),
]

// MARK: - Ana Görünüm

struct UserListView: View {
    @StateObject private var userStore = UserStore.shared
    @State private var isShowingCustomForm = false
    @State private var editingUser: UserProfile? = nil
    @State private var selectedUser: UserProfile? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    if userStore.users.isEmpty {
                        // İlk açılışta logoyu göster — boş hissi azaltır
                        VStack(spacing: 12) {
                            Image("Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 110)
                                .opacity(0.92)
                                .shadow(color: AppColor.accent.opacity(0.20), radius: 16, y: 4)
                            Text("Hazırsan başlayalım")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColor.inkMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, AppSpacing.xl)
                    } else {
                        existingCanvasesSection
                    }
                    newCanvasSection
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, 8)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColor.canvas.ignoresSafeArea())
            .navigationTitle("Kanvaslarım")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                }
            }
            .sheet(isPresented: $isShowingCustomForm) {
                UserFormView(mode: .create) { userStore.add($0) }
            }
            .sheet(item: $editingUser) { user in
                UserFormView(mode: .edit(user)) { userStore.update($0) }
            }
            .fullScreenCover(item: $selectedUser) { user in
                CanvasView(user: user)
            }
        }
    }

    // MARK: - Mevcut Kanvaslar

    private var existingCanvasesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader("Devam Et", subtitle: "Kaldığın yerden çizmeye devam et")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12),
                          GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(userStore.users) { user in
                    ExistingCanvasCard(user: user)
                        .onTapGesture {
                            HapticManager.impact(.medium)
                            selectedUser = user
                        }
                        .contextMenu {
                            Button { editingUser = user } label: {
                                Label("Yeniden Adlandır", systemImage: "pencil")
                            }
                            Divider()
                            Button(role: .destructive) {
                                userStore.delete(user)
                            } label: {
                                Label("Kanvası Sil", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    // MARK: - Yeni Kanvas

    private var newCanvasSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader("Yeni Kanvas", subtitle: "Şablon seç veya sıfırdan başla")

            HStack(spacing: 10) {
                ForEach(canvasPresets) { preset in
                    PresetCanvasCard(preset: preset) {
                        let profile = UserProfile(
                            name: preset.name,
                            avatarEmoji: preset.emoji,
                            profileColor: preset.color
                        )
                        userStore.add(profile)
                        HapticManager.impact(.medium)
                        selectedUser = profile
                    }
                }
            }

            Button {
                HapticManager.impact(.light)
                isShowingCustomForm = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .medium))
                    Text("Özelleştir")
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColor.inkMuted)
                }
                .foregroundColor(AppColor.ink)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 14)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .strokeBorder(AppColor.divider, lineWidth: 0.5)
                )
            }
        }
    }
}

// MARK: - Mevcut Kanvas Kartı

private struct ExistingCanvasCard: View {
    let user: UserProfile
    @State private var pressed = false

    var body: some View {
        VStack(spacing: 0) {
            // Üst gradient alanı
            ZStack {
                LinearGradient(
                    colors: [
                        user.profileColor.color.opacity(0.85),
                        user.profileColor.color.opacity(0.45)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 70)

                Text(user.avatarEmoji)
                    .font(.system(size: 32))
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            }

            // Alt bilgi
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(AppColor.ink)

                Text(user.createdAt, style: .date)
                    .font(.system(size: 10))
                    .foregroundColor(AppColor.inkMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppColor.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(AppColor.divider, lineWidth: 0.5)
        )
        .shadow(color: user.profileColor.color.opacity(0.15), radius: 8, y: 3)
        .scaleEffect(pressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
    }
}

// MARK: - Preset Kart

private struct PresetCanvasCard: View {
    let preset: CanvasPreset
    let onTap: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(preset.color.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Text(preset.emoji)
                        .font(.system(size: 24))
                }

                Text(preset.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(preset.description)
                    .font(.system(size: 10))
                    .foregroundColor(AppColor.inkMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .strokeBorder(preset.color.color.opacity(0.20), lineWidth: 1)
            )
            .scaleEffect(pressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
    }
}
