import Foundation
import SwiftUI

enum EmotionState: String, CaseIterable, Codable {
    case calm = "calm"
    case energetic = "energetic"
    case stressed = "stressed"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .calm:      return "Sakin"
        case .energetic: return "Enerjik"
        case .stressed:  return "Stresli"
        case .unknown:   return "Belirsiz"
        }
    }

    /// Web'den gelen Türkçe duygu adını iOS EmotionState'e çevirir.
    /// Web'in 10 duygusu iOS'un 3 kategorisine yaklaştırılır.
    static func from(displayName name: String) -> EmotionState? {
        switch name {
        case "Sakin", "Huzurlu", "Yorgun", "Odaklanmış", "Mutlu":
            return .calm
        case "Enerjik", "Heyecanlı":
            return .energetic
        case "Stresli", "Kaygılı", "Üzgün":
            return .stressed
        default:
            return nil
        }
    }
    
    var color: Color {
        switch self {
        case .calm: return Color.blue
        case .energetic: return Color.orange
        case .stressed: return Color.red
        case .unknown: return Color.gray
        }
    }
    
    var emoji: String {
        switch self {
        case .calm: return "😌"
        case .energetic: return "⚡"
        case .stressed: return "🔴"
        case .unknown: return "😶"
        }
    }
}
