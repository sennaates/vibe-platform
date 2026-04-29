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
        if case .edit = mode { return "Profili Düzenle" }
        return "Yeni Kullanıcı"
    }

    var body: some View {
        NavigationStack {
            Form {
                // Önizleme
                Section {
                    HStack {
                        Spacer()
                        avatarView(emoji: selectedEmoji, color: selectedColor.color, size: 90)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                // İsim
                Section("İsim") {
                    TextField("Kullanıcı adı", text: $name)
                }

                // Emoji seç
                Section("Avatar") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Text(emoji)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(selectedEmoji == emoji ? selectedColor.color.opacity(0.2) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedEmoji == emoji ? selectedColor.color : Color.clear, lineWidth: 2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .onTapGesture { selectedEmoji = emoji }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Renk seç
                Section("Renk") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(ProfileColor.allCases, id: \.self) { pc in
                            Circle()
                                .fill(pc.color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == pc ? 3 : 0)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColor == pc ? 1.5 : 0)
                                        .padding(3)
                                )
                                .onTapGesture { withAnimation { selectedColor = pc } }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kaydet") {
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
                        onSave(profile)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

func avatarView(emoji: String, color: Color, size: CGFloat) -> some View {
    ZStack {
        Circle()
            .fill(color.opacity(0.2))
            .frame(width: size, height: size)
        Circle()
            .strokeBorder(color.opacity(0.4), lineWidth: 2)
            .frame(width: size, height: size)
        Text(emoji)
            .font(.system(size: size * 0.45))
    }
}
