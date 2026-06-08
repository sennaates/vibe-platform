import Foundation

class UserStore: ObservableObject {
    static let shared = UserStore()

    @Published var users: [UserProfile] = []

    private var currentUserId: String?

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let name = currentUserId != nil ? "users_\(currentUserId!).json" : "users.json"
        return docs.appendingPathComponent(name)
    }

    init() {
        load()
    }

    func switchUser(to userId: String?) {
        guard self.currentUserId != userId else { return }
        self.currentUserId = userId
        if userId != nil {
            load()
        } else {
            users = []
        }
    }

    func add(_ user: UserProfile) {
        users.append(user)
        persist()
    }

    func update(_ user: UserProfile) {
        if let i = users.firstIndex(where: { $0.id == user.id }) {
            users[i] = user
            persist()
        }
    }

    func delete(_ user: UserProfile) {
        users.removeAll { $0.id == user.id }
        // Kullanıcıya ait galeri dosyasını da sil
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let galleryURL = docs.appendingPathComponent("gallery_\(user.id.uuidString).json")
        try? FileManager.default.removeItem(at: galleryURL)
        persist()
    }

    private func persist() {
        guard currentUserId != nil else { return }
        do {
            let data = try JSONEncoder().encode(users)
            try data.write(to: fileURL)
        } catch {
            print("❌ Kullanıcılar kaydedilemedi: \(error)")
        }
    }

    private func load() {
        guard currentUserId != nil else {
            users = []
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            users = try JSONDecoder().decode([UserProfile].self, from: data)
        } catch {
            users = []
        }
    }
}
