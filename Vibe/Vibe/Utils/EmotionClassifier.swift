import Foundation

class EmotionClassifier {
    
    /// Nabız değerine (BPM) göre kullanıcının duygu durumunu sınıflandırır
    /// - Parameter bpm: Kalp atış hızı (Beats Per Minute)
    /// - Returns: Sınıflandırılmış duygu durumu
    static func classify(bpm: Int) -> EmotionState {
        if bpm < 70 {
            return .calm
        } else if bpm >= 70 && bpm <= 100 {
            return .energetic
        } else {
            return .stressed
        }
    }
}
