import Foundation
import PencilKit

class DrawingStore {
    private let fileURL: URL

    init(userId: UUID) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("autosave_\(userId.uuidString).data")
    }

    func save(drawing: PKDrawing) {
        do {
            let data = drawing.dataRepresentation()
            try data.write(to: fileURL)
        } catch {
            print("❌ Çizim kaydedilemedi: \(error.localizedDescription)")
        }
    }

    func load() -> PKDrawing? {
        do {
            let data = try Data(contentsOf: fileURL)
            return try PKDrawing(data: data)
        } catch {
            return nil
        }
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
