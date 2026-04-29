import Foundation
import SwiftUI

enum EmotionState: String, CaseIterable, Codable {
    case calm = "calm"
    case energetic = "energetic"
    case stressed = "stressed"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .calm: return "Sakin"
        case .energetic: return "Enerjik"
        case .stressed: return "Stresli"
        case .unknown: return "Belirsiz"
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
