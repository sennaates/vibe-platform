import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var selectedEmoji: String = "😊"
    @State private var selectedColor: ProfileColor = .blue
    @State private var isSaving = false

    private let emojiOptions = [
        "😊","😎","🎨","🖌️","✏️","🌟","🔥","🌊","🌸","🍀",
        "🦋","🐱","🦊","🐼","🦄","⚡","🎭","💫","🎵","🧘"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Avatar önizleme
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [selectedColor.color.opacity(0.30),
                                             selectedColor.color.opacity(0.10)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        Circle()
                            .strokeBorder(selectedColor.color.opacity(0.35), lineWidth: 1)
                            .frame(width: 100, height: 100)
                        Text(selectedEmoji)
                            .font(.system(size: 46))
                    }
                    .shadow(color: selectedColor.color.opacity(0.20), radius: 14, y: 5)
                    .padding(.top, AppSpacing.lg)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedColor)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedEmoji)

                    // İsim
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        FieldLabel(title: "İSİM")
                        TextField("İsmin", text: $displayName)
                            .font(.system(size: 16))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                    .strokeBorder(AppColor.divider, lineWidth: 0.5)
                            )
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Biyografi
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        FieldLabel(title: "BİYOGRAFİ")
                        TextField("Kendinden bahset...", text: $bio, axis: .vertical)
                            .font(.system(size: 15))
                            .lineLimit(3...5)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                    .strokeBorder(AppColor.divider, lineWidth: 0.5)
                            )
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Renk
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        FieldLabel(title: "PROFİL RENGİ")
                        AppCard(padding: AppSpacing.md) {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 12) {
                                ForEach(ProfileColor.allCases, id: \.self) { color in
                                    ZStack {
                                        Circle()
                                            .fill(color.color)
                                            .frame(width: 38, height: 38)
                                        if selectedColor == color {
                                            Circle()
                                                .strokeBorder(.white, lineWidth: 2.5)
                                                .frame(width: 38, height: 38)
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .shadow(color: selectedColor == color ? color.color.opacity(0.50) : .clear, radius: 6)
                                    .scaleEffect(selectedColor == color ? 1.05 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedColor)
                                    .onTapGesture {
                                        HapticManager.selection()
                                        selectedColor = color
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Emoji
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        FieldLabel(title: "AVATAR EMOJİSİ")
                        AppCard(padding: AppSpacing.md) {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 10) {
                                ForEach(emojiOptions, id: \.self) { emoji in
                                    Text(emoji)
                                        .font(.system(size: 22))
                                        .frame(width: 44, height: 44)
                                        .background(
                                            selectedEmoji == emoji
                                            ? selectedColor.color.opacity(0.18)
                                            : AppColor.surfaceMuted
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .strokeBorder(
                                                    selectedEmoji == emoji ? selectedColor.color : Color.clear,
                                                    lineWidth: 1.5
                                                )
                                        )
                                        .scaleEffect(selectedEmoji == emoji ? 1.08 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedEmoji)
                                        .onTapGesture {
                                            HapticManager.selection()
                                            selectedEmoji = emoji
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    Spacer(minLength: AppSpacing.lg)
                }
            }
            .background(AppColor.canvas.ignoresSafeArea())
            .navigationTitle("Profili Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(AppColor.inkMuted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kaydet") { save() }
                        .fontWeight(.semibold)
                        .foregroundColor(canSave ? AppColor.accent : AppColor.inkMuted)
                        .disabled(!canSave || isSaving)
                }
            }
        }
        .onAppear {
            displayName = authService.socialUser?.displayName ?? ""
            bio = authService.socialUser?.bio ?? ""
            selectedEmoji = authService.socialUser?.avatarEmoji ?? "😊"
            selectedColor = authService.socialUser?.profileColor ?? .blue
        }
    }

    private var canSave: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func save() {
        isSaving = true
        HapticManager.impact(.medium)
        authService.updateProfile(
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            avatarEmoji: selectedEmoji,
            bio: bio,
            profileColor: selectedColor
        )
        HapticManager.notification(.success)
        dismiss()
    }
}
