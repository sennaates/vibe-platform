import Foundation
import PencilKit
import SwiftUI
import UIKit

class DrawingEngine: ObservableObject {
    @Published var currentTool: PKTool
    @Published var activeEmotion: EmotionState = .unknown
    @Published var availableColors: [Color] = []
    @Published var selectedColor: Color = .black

    init() {
        self.currentTool = PKInkingTool(.pen, color: .black, width: 5)
        updateForEmotion(.calm)
    }

    func updateForEmotion(_ emotion: EmotionState) {
        self.activeEmotion = emotion

        switch emotion {
        case .calm:
            self.availableColors = [.blue, .cyan, .mint, .green, .teal, .indigo, .purple]
            self.selectedColor = .blue
            self.currentTool = PKInkingTool(.marker, color: UIColor(.blue), width: 15)

        case .energetic:
            self.availableColors = [.yellow, .orange, .pink, .red, Color(red: 1, green: 0.8, blue: 0), Color(red: 1, green: 0.5, blue: 0)]
            self.selectedColor = .yellow
            self.currentTool = PKInkingTool(.pen, color: UIColor(.yellow), width: 8)

        case .stressed:
            self.availableColors = [.black, .red, .gray, Color(white: 0.2)]
            self.selectedColor = .black
            self.currentTool = PKInkingTool(.pencil, color: UIColor(.black), width: 2)

        case .unknown:
            self.availableColors = [.black, .gray, .blue, .red, .yellow, .green]
            self.selectedColor = .black
            self.currentTool = PKInkingTool(.pen, color: .black, width: 5)
        }
    }

    func selectColor(_ color: Color) {
        self.selectedColor = color
        if let inkingTool = currentTool as? PKInkingTool {
            self.currentTool = PKInkingTool(inkingTool.inkType, color: UIColor(color), width: inkingTool.width)
        }
    }
}
