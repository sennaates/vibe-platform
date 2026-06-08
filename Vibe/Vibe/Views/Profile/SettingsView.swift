import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    // Bildirim prefs
    @State private var notifFollows   = true
    @State private var notifLikes     = true
    @State private var notifComments  = true

    // Gizlilik
    @State private var isPrivate      = false

    // UI
    @State private var prefsLoaded    = false
    @State private var saving         = false

    // Hesap değişikliği
    @State private var showChangeEmail    = false
    @State private var showChangePassword = false
    @State private var accountActionError = ""

    // Çıkış / silme
    @State private var showDeleteAlert = false

    private let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            List {
                // Bildirimler
                Section {
                    Toggle(isOn: $notifFollows)  { label("Takip bildirimleri",  sub: "Biri seni takip ettiğinde bildir") }
                    Toggle(isOn: $notifLikes)    { label("Beğeni bildirimleri", sub: "Çizimin beğenildiğinde bildir") }
                    Toggle(isOn: $notifComments) { label("Yorum bildirimleri",  sub: "Çizimine yorum geldiğinde bildir") }
                } header: {
                    Text("Bildirimler")
                }
                .listRowBackground(AppColor.surface)
                .onChange(of: notifFollows)  { _, _ in savePrefs() }
                .onChange(of: notifLikes)    { _, _ in savePrefs() }
                .onChange(of: notifComments) { _, _ in savePrefs() }

                // Gizlilik
                Section {
                    Toggle(isOn: $isPrivate) {
                        label("Gizli hesap", sub: "Çizimlerini yalnızca takipçilerin görsün")
                    }
                } header: {
                    Text("Gizlilik")
                }
                .listRowBackground(AppColor.surface)
                .onChange(of: isPrivate) { _, _ in savePrefs() }

                // Hesap
                Section {
                    Button {
                        accountActionError = ""
                        showChangeEmail = true
                    } label: {
                        Label("E-posta Değiştir", systemImage: "envelope")
                            .foregroundColor(AppColor.ink)
                    }
                    Button {
                        accountActionError = ""
                        showChangePassword = true
                    } label: {
                        Label("Şifre Değiştir", systemImage: "lock.rotation")
                            .foregroundColor(AppColor.ink)
                    }
                } header: {
                    Text("Hesap")
                }
                .listRowBackground(AppColor.surface)

                // Oturum
                Section {
                    Button(role: .none) {
                        authService.signOut()
                        dismiss()
                    } label: {
                        Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(AppColor.ink)
                    }
                } header: {
                    Text("Oturum")
                }
                .listRowBackground(AppColor.surface)

                // Tehlikeli bölge
                Section {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Hesabı Sil", systemImage: "trash")
                    }
                } header: {
                    Text("Tehlikeli Bölge")
                }
                .listRowBackground(AppColor.surface)
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.canvas)
            .frame(maxWidth: sizeClass == .regular ? 600 : .infinity)
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(AppColor.accent)
                }
            }
        }
        .onAppear { loadPrefs() }
        .alert("Hesabı Sil", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) { deleteAccount() }
        } message: {
            Text("Bu işlem geri alınamaz. Tüm çizimleriniz ve verileriniz silinecek.")
        }
        .sheet(isPresented: $showChangeEmail) {
            ChangeEmailView()
                .environmentObject(authService)
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
                .environmentObject(authService)
        }
    }

    // MARK: - Yardımcı

    @ViewBuilder
    private func label(_ title: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColor.ink)
            Text(sub)
                .font(.system(size: 12))
                .foregroundColor(AppColor.inkMuted)
        }
    }

    // MARK: - Firestore

    private func loadPrefs() {
        guard let uid = authService.firebaseUser?.uid else { return }
        db.collection("users").document(uid).getDocument { snap, _ in
            guard let data = snap?.data() else { return }
            notifFollows  = data["notifFollows"]  as? Bool ?? true
            notifLikes    = data["notifLikes"]    as? Bool ?? true
            notifComments = data["notifComments"] as? Bool ?? true
            isPrivate     = data["isPrivate"]     as? Bool ?? false
            prefsLoaded   = true
        }
    }

    private func savePrefs() {
        guard prefsLoaded, let uid = authService.firebaseUser?.uid else { return }
        db.collection("users").document(uid).updateData([
            "notifFollows":  notifFollows,
            "notifLikes":    notifLikes,
            "notifComments": notifComments,
            "isPrivate":     isPrivate
        ], completion: nil)
    }

    private func deleteAccount() {
        guard let firebaseUser = Auth.auth().currentUser,
              let uid = authService.firebaseUser?.uid else { return }

        let group = DispatchGroup()

        // 1. Kullanıcının gönderilerini sil
        group.enter()
        db.collection("posts").whereField("userId", isEqualTo: uid)
            .getDocuments { snap, _ in
                let batch = self.db.batch()
                snap?.documents.forEach { batch.deleteDocument($0.reference) }
                batch.commit { _ in group.leave() }
            }

        // 2. Follow ilişkilerini sil (followerId == uid veya followedId == uid)
        group.enter()
        db.collection("follows").whereField("followerId", isEqualTo: uid)
            .getDocuments { snap, _ in
                let batch = self.db.batch()
                snap?.documents.forEach { batch.deleteDocument($0.reference) }
                batch.commit { _ in group.leave() }
            }

        group.enter()
        db.collection("follows").whereField("followedId", isEqualTo: uid)
            .getDocuments { snap, _ in
                let batch = self.db.batch()
                snap?.documents.forEach { batch.deleteDocument($0.reference) }
                batch.commit { _ in group.leave() }
            }

        // 3. Bildirimleri sil (hedef veya kaynak kullanıcı)
        group.enter()
        db.collection("notifications").whereField("targetUserId", isEqualTo: uid)
            .getDocuments { snap, _ in
                let batch = self.db.batch()
                snap?.documents.forEach { batch.deleteDocument($0.reference) }
                batch.commit { _ in group.leave() }
            }

        group.enter()
        db.collection("notifications").whereField("fromUserId", isEqualTo: uid)
            .getDocuments { snap, _ in
                let batch = self.db.batch()
                snap?.documents.forEach { batch.deleteDocument($0.reference) }
                batch.commit { _ in group.leave() }
            }

        // 4. userLikes alt koleksiyonunu sil
        group.enter()
        db.collection("userLikes").document(uid).collection("items")
            .getDocuments { snap, _ in
                let batch = self.db.batch()
                snap?.documents.forEach { batch.deleteDocument($0.reference) }
                batch.commit { _ in group.leave() }
            }

        // Hepsi bitince kullanıcı dokümanını ve Auth hesabını sil
        group.notify(queue: .main) {
            let batch = self.db.batch()
            batch.deleteDocument(self.db.collection("users").document(uid))
            batch.commit { _ in
                firebaseUser.delete { _ in
                    DispatchQueue.main.async {
                        self.authService.signOut()
                        self.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - E-posta Değiştir

struct ChangeEmailView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newEmail        = ""
    @State private var loading         = false
    @State private var error           = ""
    @State private var success         = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Mevcut Şifre")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColor.inkMuted)
                    SecureField("Şifreniz", text: $currentPassword)
                        .textContentType(.password)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppColor.surface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColor.divider, lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Yeni E-posta")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColor.inkMuted)
                    TextField("yeni@ornek.com", text: $newEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppColor.surface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColor.divider, lineWidth: 1))
                }

                if !error.isEmpty {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if success {
                    Text("E-posta güncellendi. Doğrulama e-postası gönderildi.")
                        .font(.system(size: 13))
                        .foregroundColor(.green)
                }

                Button {
                    changeEmail()
                } label: {
                    Group {
                        if loading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Güncelle")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColor.accent)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(loading || newEmail.isEmpty || currentPassword.isEmpty)

                Spacer()
            }
            .padding(20)
            .background(AppColor.canvas.ignoresSafeArea())
            .navigationTitle("E-posta Değiştir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }.foregroundColor(AppColor.accent)
                }
            }
        }
    }

    private func changeEmail() {
        guard let user = Auth.auth().currentUser,
              let currentEmail = user.email else { return }
        loading = true; error = ""

        let credential = EmailAuthProvider.credential(withEmail: currentEmail, password: currentPassword)
        user.reauthenticate(with: credential) { _, err in
            if let err {
                self.error = err.localizedDescription
                self.loading = false
                return
            }
            user.sendEmailVerification(beforeUpdatingEmail: newEmail) { err in
                DispatchQueue.main.async {
                    self.loading = false
                    if let err {
                        self.error = err.localizedDescription
                    } else {
                        self.success = true
                    }
                }
            }
        }
    }
}

// MARK: - Şifre Değiştir

struct ChangePasswordView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword     = ""
    @State private var confirmPassword = ""
    @State private var loading         = false
    @State private var error           = ""
    @State private var success         = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Mevcut Şifre")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColor.inkMuted)
                    SecureField("Mevcut şifreniz", text: $currentPassword)
                        .textContentType(.password)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppColor.surface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColor.divider, lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Yeni Şifre")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColor.inkMuted)
                    SecureField("En az 6 karakter", text: $newPassword)
                        .textContentType(.newPassword)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppColor.surface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColor.divider, lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Yeni Şifre (Tekrar)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColor.inkMuted)
                    SecureField("Şifreyi tekrar girin", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppColor.surface)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColor.divider, lineWidth: 1))
                }

                if !error.isEmpty {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if success {
                    Text("Şifre başarıyla güncellendi.")
                        .font(.system(size: 13))
                        .foregroundColor(.green)
                }

                Button {
                    changePassword()
                } label: {
                    Group {
                        if loading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Güncelle")
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColor.accent)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(loading || newPassword.isEmpty || currentPassword.isEmpty)

                Spacer()
            }
            .padding(20)
            .background(AppColor.canvas.ignoresSafeArea())
            .navigationTitle("Şifre Değiştir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }.foregroundColor(AppColor.accent)
                }
            }
        }
    }

    private func changePassword() {
        guard newPassword.count >= 6 else {
            error = "Yeni şifre en az 6 karakter olmalı."; return
        }
        guard newPassword == confirmPassword else {
            error = "Şifreler eşleşmiyor."; return
        }
        guard let user = Auth.auth().currentUser,
              let email = user.email else { return }

        loading = true; error = ""
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        user.reauthenticate(with: credential) { _, err in
            if let err {
                DispatchQueue.main.async {
                    self.error = err.localizedDescription
                    self.loading = false
                }
                return
            }
            user.updatePassword(to: self.newPassword) { err in
                DispatchQueue.main.async {
                    self.loading = false
                    if let err {
                        self.error = err.localizedDescription
                    } else {
                        self.success = true
                        self.currentPassword = ""
                        self.newPassword = ""
                        self.confirmPassword = ""
                    }
                }
            }
        }
    }
}
