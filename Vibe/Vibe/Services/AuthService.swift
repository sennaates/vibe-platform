import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var firebaseUser: User? = nil
    @Published var socialUser: SocialUser? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let db = Firestore.firestore()
    private var handle: AuthStateDidChangeListenerHandle?

    var isLoggedIn: Bool { firebaseUser != nil }

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.firebaseUser = user
            if let user {
                self?.fetchSocialUser(uid: user.uid)
            } else {
                self?.socialUser = nil
            }
        }
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    // MARK: - Email Auth

    func signUp(email: String, password: String, displayName: String, avatarEmoji: String, profileColor: ProfileColor) {
        isLoading = true
        errorMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self else { return }
            if let error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                return
            }
            guard let uid = result?.user.uid else { return }

            let user = SocialUser(
                id: uid,
                displayName: displayName,
                avatarEmoji: avatarEmoji,
                profileColorRaw: profileColor.rawValue,
                bio: "",
                followerCount: 0,
                followingCount: 0,
                postCount: 0,
                createdAt: Date()
            )
            self.createUserDocument(user)
        }
    }

    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            self?.isLoading = false
            if let error {
                self?.errorMessage = error.localizedDescription
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        socialUser = nil
    }

    // MARK: - Firestore

    private func createUserDocument(_ user: SocialUser) {
        db.collection("users").document(user.id).setData(user.dict) { [weak self] error in
            self?.isLoading = false
            if let error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.socialUser = user
            }
        }
    }

    func fetchSocialUser(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let data = snapshot?.data() else { return }
            self?.socialUser = SocialUser.from(data, id: uid)
        }
    }

    func updateProfile(displayName: String, avatarEmoji: String, bio: String, profileColor: ProfileColor? = nil) {
        guard let uid = firebaseUser?.uid else { return }
        var updates: [String: Any] = [
            "displayName": displayName,
            "avatarEmoji": avatarEmoji,
            "bio": bio
        ]
        if let profileColor {
            updates["profileColorRaw"] = profileColor.rawValue
        }
        db.collection("users").document(uid).updateData(updates) { [weak self] _ in
            DispatchQueue.main.async {
                self?.socialUser?.displayName = displayName
                self?.socialUser?.avatarEmoji = avatarEmoji
                self?.socialUser?.bio = bio
                if let profileColor {
                    self?.socialUser?.profileColorRaw = profileColor.rawValue
                }
            }
        }
    }
}
