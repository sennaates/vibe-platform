import SwiftUI
import PencilKit
import UIKit

struct PKCanvasViewWrapper: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @ObservedObject var drawingEngine: DrawingEngine
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput // Parmakla çizime de izin ver (test için)
        canvasView.tool = drawingEngine.currentTool
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.delegate = context.coordinator
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Motorun tool'u değiştiğinde canvas'a yansıt
        uiView.tool = drawingEngine.currentTool
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PKCanvasViewWrapper
        
        init(_ parent: PKCanvasViewWrapper) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Çizim değiştiğinde otomatik kaydet
            DrawingStore.shared.save(drawing: canvasView.drawing)
        }
    }
}
