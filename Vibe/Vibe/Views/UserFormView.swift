import SwiftUI

struct UserFormView: View {
    @Environment(\.dismiss) private var dismiss

    enum Mode {
        case create
        case edit(UserProfile)
    }

    let mode: Mode
    let onSave: (UserProfile) -> Void

    @State private var name: String = ""
    @State private var selectedEmoji: String = "😊"
    @State private var selectedColor: ProfileColor = .blue

    private let emojiOptions = [
        "😊","😎","🎨","🖌️","✏️","🌟","🔥","🌊","🌸","🍀",
        "🦋","🐱","🐶","🦊","🐼","🦄","🐸","🌈","⚡","🎭",
        "🧠","💫","🎵","🏄","🧘","🤩","😈","🥰","😤","🥶"
    ]

    init(mode: Mode, onSave: @escaping (UserProfile) -> Void) {
        self.mode = mode
        self.onSave = onSave

        if case .edit(let user) = mode {
            _name = State(initialValue: user.name)
            _selectedEmoji = State(initialValue: user.avatarEmoji)
            _selectedColor = State(initialValue: user.profileColor)
        }
    }

    var title: String {
        if case .edit = mode { return "Kanvası Düzenle" }
        return "Yeni Kanvas"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {

                    // Avatar önizleme
                    avatarPreview
                        .padding(.top, AppSpacing.lg)

                    // İsim alanı
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        FieldLabel(title: "KANVAS ADI")
                        nameField
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Renk seçici
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        FieldLabel(title: "RENK")
                        colorPicker
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    // Emoji seçici
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        FieldLabel(title: "AVATAR")
                        emojiPicker
                    }
                    .padding(.horizontal, AppSpacing.lg)

                    Spacer(minLength: AppSpacing.xl)
                }
            }
            .background(AppColor.canvas.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(AppColor.inkMuted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kaydet") { save() }
                        .fontWeight(.semibold)
                        .foregroundColor(name.trimmingCharacters(in: .whitespaces).isEmpty
                                         ? AppColor.inkMuted
                                         : AppColor.accent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Avatar Önizleme

    private var avatarPreview: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            selectedColor.color.opacity(0.30),
                            selectedColor.color.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 110, height: 110)

            Circle()
                .strokeBorder(selectedColor.color.opacity(0.35), lineWidth: 1)
                .frame(width: 110, height: 110)

            Text(selectedEmoji)
                .font(.system(size: 50))
        }
        .shadow(color: selectedColor.color.opacity(0.20), radius: 14, y: 5)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedColor)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedEmoji)
    }

    // MARK: - İsim Alanı

    private var nameField: some View {
        TextField("ör. Günlük Çizimlerim", text: $name)
            .font(.system(size: 16))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(AppColor.divider, lineWidth: 0.5)
            )
            .autocorrectionDisabled()
    }

    // MARK: - Renk Seçici

    private var colorPicker: some View {
        AppCard(padding: AppSpacing.md) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 12) {
                ForEach(ProfileColor.allCases, id: \.self) { pc in
                    ZStack {
                        Circle()
                            .fill(pc.color)
                            .frame(width: 38, height: 38)
                        if selectedColor == pc {
                            Circle()
                                .strokeBorder(.white, lineWidth: 2.5)
                                .frame(width: 38, height: 38)
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .shadow(color: selectedColor == pc ? pc.color.opacity(0.55) : .clear, radius: 6)
                    .scaleEffect(selectedColor == pc ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedColor)
                    .onTapGesture {
                        HapticManager.selection()
                        selectedColor = pc
                    }
                }
            }
        }
    }

    // MARK: - Emoji Seçici

    private var emojiPicker: some View {
        AppCard(padding: AppSpacing.md) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 10) {
                ForEach(emojiOptions, id: \.self) { emoji in
                    Text(emoji)
                        .font(.system(size: 22))
                        .frame(width: 42, height: 42)
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

    // MARK: - Kaydet

    private func save() {
        let profile: UserProfile
        if case .edit(let existing) = mode {
            profile = UserProfile(
                id: existing.id,
                name: name.trimmingCharacters(in: .whitespaces),
                avatarEmoji: selectedEmoji,
                profileColor: selectedColor
            )
        } else {
            profile = UserProfile(
                name: name.trimmingCharacters(in: .whitespaces),
                avatarEmoji: selectedEmoji,
                profileColor: selectedColor
            )
        }
        HapticManager.notification(.success)
        onSave(profile)
        dismiss()
    }
}

// MARK: - Avatar Yardımcı Fonksiyonu

func avatarView(emoji: String, color: Color, size: CGFloat) -> some View {
    ZStack {
        Circle()
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.32), color.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
        Circle()
            .strokeBorder(color.opacity(0.35), lineWidth: 1.5)
            .frame(width: size, height: size)
        Text(emoji)
            .font(.system(size: size * 0.45))
    }
}
