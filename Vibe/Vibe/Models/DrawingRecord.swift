import Foundation
import PencilKit
import UIKit

struct DrawingRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let emotion: EmotionState
    let drawingData: Data

    init(id: UUID = UUID(), date: Date = Date(), emotion: EmotionState, drawing: PKDrawing) {
        self.id = id
        self.date = date
        self.emotion = emotion
        self.drawingData = drawing.dataRepresentation()
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
