import Foundation

class EmotionClassifier {
    static func classify(bpm: Int) -> EmotionState {
        if bpm < 70 {
            return .calm
        } else if bpm <= 100 {
            return .energetic
        } else {
            return .stressed
        }
    }
}
