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
    var bgType: CanvasBgType        // Kanvas arkaplan tipi (eski kayıtlarda .blank varsayılır)
    var bgColorHex: String          // Kanvas arkaplan rengi (#RRGGBB formatında)

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        emotion: EmotionState,
        drawing: PKDrawing,
        bpmHistory: [BpmSample] = [],
        bgType: CanvasBgType = .blank,
        bgColorHex: String = "#FFFFFF"
    ) {
        self.id = id
        self.date = date
        self.emotion = emotion
        self.drawingData = drawing.dataRepresentation()
        self.bpmHistory = bpmHistory
        self.bgType = bgType
        self.bgColorHex = bgColorHex
    }

    var drawing: PKDrawing? {
        try? PKDrawing(data: drawingData)
    }

    /// Arkaplan rengi UIColor olarak
    var bgUIColor: UIColor {
        UIColor(hex: bgColorHex) ?? .systemBackground
    }

    func thumbnail(size: CGSize = CGSize(width: 300, height: 220)) -> UIImage? {
        guard let drawing = drawing else { return nil }
        let bounds = CGRect(origin: .zero, size: size)
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { ctx in
            let cgCtx = ctx.cgContext

            // 1. Arkaplan rengi
            bgUIColor.setFill()
            cgCtx.fill(bounds)

            // 2. Izgara / çizgi deseni
            let lineColor = UIColor.label.withAlphaComponent(0.08)
            lineColor.setStroke()
            cgCtx.setLineWidth(0.5)
            let path = UIBezierPath()
            if bgType == .grid {
                let step: CGFloat = 20
                var x = step
                while x < bounds.width  { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: bounds.height)); x += step }
                var y = step
                while y < bounds.height { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: bounds.width, y: y)); y += step }
            } else if bgType == .lined {
                let step: CGFloat = 24
                var y = step
                while y < bounds.height { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: bounds.width, y: y)); y += step }
            }
            path.stroke()

            // 3. Çizim katmanı — orijinal çizimi küçülterek merkeze sığdır
            let drawBounds: CGRect
            if drawing.strokes.isEmpty {
                drawBounds = bounds
            } else {
                let strokeBounds = drawing.bounds.insetBy(dx: -10, dy: -10)
                let scale = min(bounds.width / strokeBounds.width, bounds.height / strokeBounds.height, 1)
                let w = strokeBounds.width  * scale
                let h = strokeBounds.height * scale
                drawBounds = CGRect(
                    x: (bounds.width  - w) / 2,
                    y: (bounds.height - h) / 2,
                    width: w, height: h
                )
            }
            let strokeImage = drawing.image(from: drawing.strokes.isEmpty ? bounds : drawing.bounds.insetBy(dx: -10, dy: -10), scale: UIScreen.main.scale)
            strokeImage.draw(in: drawBounds)
        }
    }
}
