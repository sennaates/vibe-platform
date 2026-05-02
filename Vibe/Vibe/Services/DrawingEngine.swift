import Foundation
import PencilKit
import SwiftUI
import UIKit

class DrawingEngine: ObservableObject {
    @Published var currentTool: PKTool
    @Published var activeEmotion: EmotionState = .unknown
    @Published var availableColors: [Color] = []
    @Published var selectedColor: Color = .black
    @Published var brushSize: CGFloat = 8
    @Published var isEraserActive: Bool = false

    private var baseInkType: PKInkingTool.InkType = .pen

    init() {
        self.currentTool = PKInkingTool(.pen, color: .black, width: 8)
        updateForEmotion(.calm)
    }

    func updateForEmotion(_ emotion: EmotionState) {
        self.activeEmotion = emotion
        self.isEraserActive = false

        switch emotion {
        case .calm:
            self.availableColors = [.blue, .cyan, .mint, .green, .teal, .indigo, .purple]
            self.selectedColor = .blue
            self.brushSize = 15
            self.baseInkType = .marker

        case .energetic:
            self.availableColors = [.yellow, .orange, .pink, .red, Color(red: 1, green: 0.8, blue: 0), Color(red: 1, green: 0.5, blue: 0)]
            self.selectedColor = .yellow
            self.brushSize = 8
            self.baseInkType = .pen

        case .stressed:
            self.availableColors = [.black, .red, .gray, Color(white: 0.2)]
            self.selectedColor = .black
            self.brushSize = 2
            self.baseInkType = .pencil

        case .unknown:
            self.availableColors = [.black, .gray, .blue, .red, .yellow, .green]
            self.selectedColor = .black
            self.brushSize = 5
            self.baseInkType = .pen
        }

        applyInkingTool()
    }

    func selectColor(_ color: Color) {
        self.selectedColor = color
        self.isEraserActive = false
        applyInkingTool()
    }

    func setBrushSize(_ size: CGFloat) {
        self.brushSize = size
        if isEraserActive {
            self.currentTool = PKEraserTool(.bitmap, width: size * 2)
        } else {
            applyInkingTool()
        }
    }

    func toggleEraser() {
        isEraserActive.toggle()
        if isEraserActive {
            self.currentTool = PKEraserTool(.bitmap, width: brushSize * 2)
        } else {
            applyInkingTool()
        }
    }

    private func applyInkingTool() {
        self.currentTool = PKInkingTool(baseInkType, color: UIColor(selectedColor), width: brushSize)
    }
}
