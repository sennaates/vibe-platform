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

    // Çıkış / silme
    @State private var showDeleteAlert = false
    @State private var deleteConfirmText = ""

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
        guard let user = Auth.auth().currentUser,
              let uid  = authService.firebaseUser?.uid else { return }

        // Kullanıcı dokümanını sil
        let batch = db.batch()
        batch.deleteDocument(db.collection("users").document(uid))
        batch.commit { _ in
            // Firebase Auth hesabını sil
            user.delete { _ in
                authService.signOut()
                dismiss()
            }
        }
    }
}
