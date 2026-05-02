import SwiftUI

// MARK: - Ana Auth View

struct AuthView: View {
    @EnvironmentObject var authService: AuthService
    @State private var mode: AuthMode = .signIn
    @State private var signUpStep: Int = 1      // 1 = kimlik, 2 = avatar

    // Ortak alanlar
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var selectedEmoji = "😊"
    @State private var selectedColor: ProfileColor = .purple

    // Animasyon
    @State private var blobOffset1 = CGPoint(x: -60, y: -120)
    @State private var blobOffset2 = CGPoint(x: 80, y: 100)
    @State private var blobOffset3 = CGPoint(x: 20, y: -60)
    @State private var logoScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0

    private let emojiOptions = [
        "😊","😎","🎨","🖌️","✏️","🌟","🔥","🌊","🌸","🍀",
        "🦋","🐱","🦊","🐼","🦄","⚡","🎭","💫","🎵","🧘"
    ]

    enum AuthMode { case signIn, signUp }

    var body: some View {
        ZStack {
            // ── Arka plan ──────────────────────────────────────
            backgroundLayer

            // ── İçerik ────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Logo alanı
                    logoSection
                        .padding(.top, 72)
                        .padding(.bottom, 36)

                    // Kart
                    VStack(spacing: 0) {
                        // Mod seçici (sadece ilk adımda)
                        if mode == .signIn || signUpStep == 1 {
                            modePicker
                                .padding(.bottom, 28)
                        }

                        // Hata mesajı
                        if let error = authService.errorMessage {
                            errorBanner(error)
                                .padding(.bottom, 16)
                        }

                        // Form
                        if mode == .signIn {
                            signInForm
                        } else {
                            if signUpStep == 1 {
                                signUpStep1
                            } else {
                                signUpStep2
                            }
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 24, y: 8)
                    .padding(.horizontal, 20)

                    // Geçiş linki
                    switchModeButton
                        .padding(.top, 24)
                        .padding(.bottom, 48)
                }
            }
            .opacity(contentOpacity)
        }
        .ignoresSafeArea()
        .onAppear { startAnimations() }
        .onChange(of: mode) { _, _ in
            signUpStep = 1
            authService.errorMessage = nil
        }
    }

    // MARK: - Arka Plan

    private var backgroundLayer: some View {
        ZStack {
            // Koyu gradient
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.04, blue: 0.28),
                    Color(red: 0.06, green: 0.02, blue: 0.18),
                    Color(red: 0.02, green: 0.01, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Animasyonlu bloblar
            blob(color: Color(red: 0.55, green: 0.20, blue: 0.90),
                 size: 320, offset: blobOffset1, blur: 80)

            blob(color: Color(red: 0.25, green: 0.10, blue: 0.75),
                 size: 260, offset: blobOffset2, blur: 70)

            blob(color: Color(red: 0.70, green: 0.30, blue: 0.95),
                 size: 200, offset: blobOffset3, blur: 60)
        }
    }

    private func blob(color: Color, size: CGFloat, offset: CGPoint, blur: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(0.35))
            .frame(width: size, height: size)
            .offset(x: offset.x, y: offset.y)
            .blur(radius: blur)
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: 14) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 120)
                .scaleEffect(logoScale)
                .shadow(color: .black.opacity(0.25), radius: 18, y: 6)

            Text("vibe")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(red: 0.92, green: 0.82, blue: 1.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .tracking(2)

            Text(modeSubtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .animation(.easeInOut(duration: 0.3), value: mode)
                .animation(.easeInOut(duration: 0.3), value: signUpStep)
        }
    }

    private var modeSubtitle: String {
        if mode == .signIn { return "Hesabına giriş yap" }
        return signUpStep == 1 ? "Hesap oluştur" : "Profilini özelleştir"
    }

    // MARK: - Mod Seçici

    private var modePicker: some View {
        HStack(spacing: 0) {
            pickerTab(title: "Giriş Yap", isSelected: mode == .signIn) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    mode = .signIn
                }
            }
            pickerTab(title: "Kayıt Ol", isSelected: mode == .signUp) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    mode = .signUp
                }
            }
        }
        .background(Color(UIColor.tertiarySystemBackground).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func pickerTab(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { HapticManager.selection(); action() }) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    isSelected
                    ? Color(UIColor.systemBackground).opacity(0.9)
                    : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(3)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
    }

    // MARK: - Hata Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Giriş Formu

    private var signInForm: some View {
        VStack(spacing: 16) {
            authField(icon: "envelope", placeholder: "E-posta", text: $email,
                      keyboard: .emailAddress, autoCapitalize: false)

            authField(icon: "lock", placeholder: "Şifre", text: $password,
                      isSecure: true)

            primaryButton(title: "Giriş Yap", icon: "arrow.right") {
                authService.signIn(email: email, password: password)
            }
            .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
            .padding(.top, 4)
        }
    }

    // MARK: - Kayıt Adım 1: Kimlik

    private var signUpStep1: some View {
        VStack(spacing: 16) {
            authField(icon: "person", placeholder: "Kullanıcı adı", text: $displayName,
                      autoCapitalize: false)

            authField(icon: "envelope", placeholder: "E-posta", text: $email,
                      keyboard: .emailAddress, autoCapitalize: false)

            authField(icon: "lock", placeholder: "Şifre (min. 6 karakter)", text: $password,
                      isSecure: true)

            primaryButton(title: "Devam", icon: "arrow.right") {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    signUpStep = 2
                }
            }
            .disabled(displayName.isEmpty || email.isEmpty || password.count < 6)
            .padding(.top, 4)
        }
    }

    // MARK: - Kayıt Adım 2: Avatar

    private var signUpStep2: some View {
        VStack(spacing: 20) {
            // Adım başlığı
            HStack {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        signUpStep = 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .clipShape(Circle())
                }
                Spacer()
                // Önizleme avatar
                avatarView(emoji: selectedEmoji, color: selectedColor.color, size: 52)
                Spacer()
                // Boşluk dengesi
                Color.clear.frame(width: 36, height: 36)
            }

            // Renk seçici
            VStack(alignment: .leading, spacing: 10) {
                Label("Profil Rengi", systemImage: "paintpalette")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: 10) {
                    ForEach(ProfileColor.allCases, id: \.self) { pc in
                        ZStack {
                            Circle()
                                .fill(pc.color)
                                .frame(width: 32, height: 32)
                            if selectedColor == pc {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 2.5)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .shadow(color: selectedColor == pc ? pc.color.opacity(0.6) : .clear, radius: 5)
                        .onTapGesture {
                            HapticManager.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedColor = pc
                            }
                        }
                    }
                }
            }

            // Emoji seçici
            VStack(alignment: .leading, spacing: 10) {
                Label("Avatar Emojisi", systemImage: "face.smiling")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                    ForEach(emojiOptions, id: \.self) { emoji in
                        Text(emoji)
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(
                                selectedEmoji == emoji
                                ? selectedColor.color.opacity(0.22)
                                : Color(UIColor.tertiarySystemBackground)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedEmoji == emoji ? selectedColor.color : Color.clear, lineWidth: 2)
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

            primaryButton(title: "Hesap Oluştur", icon: "sparkles", isLoading: authService.isLoading) {
                authService.signUp(
                    email: email,
                    password: password,
                    displayName: displayName,
                    avatarEmoji: selectedEmoji,
                    profileColor: selectedColor
                )
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Mod Geçiş Butonu

    private var switchModeButton: some View {
        Button {
            HapticManager.selection()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                mode = (mode == .signIn) ? .signUp : .signIn
            }
        } label: {
            Group {
                if mode == .signIn {
                    Text("Hesabın yok mu? ") + Text("Kayıt Ol").bold()
                } else {
                    Text("Zaten hesabın var mı? ") + Text("Giriş Yap").bold()
                }
            }
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.65))
        }
    }

    // MARK: - Bileşenler

    private func authField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        autoCapitalize: Bool = true,
        isSecure: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .autocapitalization(autoCapitalize ? .words : .none)
                    .autocorrectionDisabled()
            }
        }
        .font(.body)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(UIColor.tertiarySystemBackground).opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func primaryButton(
        title: String,
        icon: String,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticManager.impact(.medium)
            action()
        } label: {
            ZStack {
                // Gradient dolgu
                LinearGradient(
                    colors: [
                        Color(red: 0.55, green: 0.25, blue: 0.95),
                        Color(red: 0.35, green: 0.10, blue: 0.80)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color(red: 0.45, green: 0.15, blue: 0.85).opacity(0.5), radius: 12, y: 4)
        }
        .disabled(isLoading)
    }

    // MARK: - Başlangıç Animasyonları

    private func startAnimations() {
        // Blob hareketi
        withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
            blobOffset1 = CGPoint(x: 60, y: -80)
        }
        withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
            blobOffset2 = CGPoint(x: -50, y: 80)
        }
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            blobOffset3 = CGPoint(x: -30, y: 50)
        }

        // Logo giriş
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            logoScale = 1.0
        }

        // İçerik fade-in
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            contentOpacity = 1
        }
    }
}
