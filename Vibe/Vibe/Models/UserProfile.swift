import Foundation
import SwiftUI

enum ProfileColor: String, CaseIterable, Codable {
    case blue, orange, red, green, purple, pink, teal, indigo, yellow, mint

    var color: Color {
        switch self {
        case .blue:   return .blue
        case .orange: return .orange
        case .red:    return .red
        case .green:  return .green
        case .purple: return .purple
        case .pink:   return .pink
        case .teal:   return .teal
        case .indigo: return .indigo
        case .yellow: return .yellow
        case .mint:   return .mint
        }
    }
}

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var avatarEmoji: String
    var profileColor: ProfileColor
    let createdAt: Date

    init(id: UUID = UUID(), name: String, avatarEmoji: String, profileColor: ProfileColor) {
        self.id = id
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.profileColor = profileColor
        self.createdAt = Date()
    }
}
