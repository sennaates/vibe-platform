import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isSignUp = true
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var selectedEmoji = "😊"
    @State private var selectedColor: ProfileColor = .blue

    private let emojiOptions = ["😊","😎","🎨","🖌️","✏️","🌟","🔥","🌊","🌸","🍀","🦋","🐱","🦊","🐼","🦄","⚡","🎭","💫","🎵","🧘"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    VStack(spacing: 8) {
                        Text("🎨")
                            .font(.system(size: 60))
                        Text("Vibe")
                            .font(.largeTitle.weight(.bold))
                        Text(isSignUp ? "Hesap Oluştur" : "Giriş Yap")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    if let error = authService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }

                    VStack(spacing: 14) {
                        if isSignUp {
                            // Avatar seçimi
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Avatarın")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)

                                // Önizleme
                                HStack {
                                    Spacer()
                                    avatarView(emoji: selectedEmoji, color: selectedColor.color, size: 70)
                                    Spacer()
                                }

                                // Emoji grid
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                                    ForEach(emojiOptions, id: \.self) { emoji in
                                        Text(emoji)
                                            .font(.title3)
                                            .frame(width: 44, height: 44)
                                            .background(selectedEmoji == emoji ? selectedColor.color.opacity(0.2) : Color(UIColor.secondarySystemBackground))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(selectedEmoji == emoji ? selectedColor.color : Color.clear, lineWidth: 2))
                                            .onTapGesture { selectedEmoji = emoji }
                                    }
                                }

                                // Renk seçimi
                                HStack(spacing: 10) {
                                    ForEach(ProfileColor.allCases, id: \.self) { pc in
                                        Circle()
                                            .fill(pc.color)
                                            .frame(width: 28, height: 28)
                                            .overlay(Circle().stroke(Color.primary, lineWidth: selectedColor == pc ? 2.5 : 0))
                                            .onTapGesture { withAnimation { selectedColor = pc } }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(16)

                            TextField("Kullanıcı adı", text: $displayName)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                        }

                        TextField("E-posta", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()

                        SecureField("Şifre", text: $password)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)

                    // Ana buton
                    Button {
                        HapticManager.impact(.medium)
                        if isSignUp {
                            authService.signUp(
                                email: email,
                                password: password,
                                displayName: displayName,
                                avatarEmoji: selectedEmoji,
                                profileColor: selectedColor
                            )
                        } else {
                            authService.signIn(email: email, password: password)
                        }
                    } label: {
                        Group {
                            if authService.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isSignUp ? "Hesap Oluştur" : "Giriş Yap")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(14)
                    }
                    .disabled(authService.isLoading || email.isEmpty || password.isEmpty || (isSignUp && displayName.isEmpty))
                    .padding(.horizontal)

                    // Geçiş
                    Button {
                        withAnimation { isSignUp.toggle() }
                        authService.errorMessage = nil
                    } label: {
                        Text(isSignUp ? "Zaten hesabın var mı? **Giriş Yap**" : "Hesabın yok mu? **Kayıt Ol**")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
    }
}
