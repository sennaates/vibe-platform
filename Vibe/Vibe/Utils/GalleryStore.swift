import Foundation
import PencilKit

class GalleryStore: ObservableObject {
    @Published var records: [DrawingRecord] = []

    private let indexURL: URL

    init(userId: UUID) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        indexURL = docs.appendingPathComponent("gallery_\(userId.uuidString).json")
        load()
    }

    func save(drawing: PKDrawing, emotion: EmotionState) {
        let record = DrawingRecord(emotion: emotion, drawing: drawing)
        records.insert(record, at: 0)
        persist()
    }

    func delete(record: DrawingRecord) {
        records.removeAll { $0.id == record.id }
        persist()
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: indexURL)
        } catch {
            print("❌ Galeri kaydedilemedi: \(error)")
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: indexURL)
            records = try JSONDecoder().decode([DrawingRecord].self, from: data)
        } catch {
            records = []
        }
    }
}
