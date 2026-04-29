import Foundation
import PencilKit

class DrawingStore {
    static let shared = DrawingStore()
    private let fileURL: URL

    init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        fileURL = paths[0].appendingPathComponent("autosave_drawing.data")
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
