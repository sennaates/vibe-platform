import Foundation
import PencilKit
import UIKit

// MARK: - BPM Örneği
struct BpmSample: Codable, Identifiable {
    var id: Double { secondsFromStart }
    let secondsFromStart: Double   // Oturum başından itibaren geçen saniye
    let bpm: Int
}

// MARK: - Çizim Kaydı
struct DrawingRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let emotion: EmotionState
    let drawingData: Data
    var bpmHistory: [BpmSample]     // Çizim sırasında kaydedilen BPM geçmişi

    init(id: UUID = UUID(), date: Date = Date(), emotion: EmotionState, drawing: PKDrawing, bpmHistory: [BpmSample] = []) {
        self.id = id
        self.date = date
        self.emotion = emotion
        self.drawingData = drawing.dataRepresentation()
        self.bpmHistory = bpmHistory
    }

    var drawing: PKDrawing? {
        try? PKDrawing(data: drawingData)
    }

    func thumbnail(size: CGSize = CGSize(width: 300, height: 220)) -> UIImage? {
        guard let drawing = drawing else { return nil }
        let bounds = drawing.strokes.isEmpty
            ? CGRect(origin: .zero, size: size)
            : drawing.bounds.insetBy(dx: -20, dy: -20)
        return drawing.image(from: bounds, scale: UIScreen.main.scale)
    }
}
