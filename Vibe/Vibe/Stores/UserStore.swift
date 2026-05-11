import Foundation

class UserStore: ObservableObject {
    static let shared = UserStore()

    @Published var users: [UserProfile] = []

    private let fileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("users.json")
        load()
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
        do {
            let data = try JSONEncoder().encode(users)
            try data.write(to: fileURL)
        } catch {
            print("❌ Kullanıcılar kaydedilemedi: \(error)")
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            users = try JSONDecoder().decode([UserProfile].self, from: data)
        } catch {
            users = []
        }
    }
}
