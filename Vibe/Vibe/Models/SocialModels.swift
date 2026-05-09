import Foundation
import SwiftUI

struct SocialUser: Identifiable {
    let id: String          // Firebase UID
    var displayName: String
    var avatarEmoji: String
    var profileColorRaw: String
    var bio: String
    var followerCount: Int
    var followingCount: Int
    var postCount: Int
    var createdAt: Date

    var profileColor: ProfileColor {
        ProfileColor(rawValue: profileColorRaw) ?? .blue
    }

    var dict: [String: Any] {
        [
            "displayName": displayName,
            "avatarEmoji": avatarEmoji,
            "profileColorRaw": profileColorRaw,
            "bio": bio,
            "followerCount": followerCount,
            "followingCount": followingCount,
            "postCount": postCount,
            "createdAt": createdAt
        ]
    }

    static func from(_ dict: [String: Any], id: String) -> SocialUser? {
        guard
            let displayName = dict["displayName"] as? String,
            let avatarEmoji = dict["avatarEmoji"] as? String,
            let profileColorRaw = dict["profileColorRaw"] as? String
        else { return nil }

        return SocialUser(
            id: id,
            displayName: displayName,
            avatarEmoji: avatarEmoji,
            profileColorRaw: profileColorRaw,
            bio: dict["bio"] as? String ?? "",
            followerCount: dict["followerCount"] as? Int ?? 0,
            followingCount: dict["followingCount"] as? Int ?? 0,
            postCount: dict["postCount"] as? Int ?? 0,
            createdAt: (dict["createdAt"] as? Date) ?? Date()
        )
    }
}

struct Post: Identifiable, Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Post, rhs: Post) -> Bool { lhs.id == rhs.id }
    let id: String
    let userId: String
    let userDisplayName: String
    let userAvatarEmoji: String
    let userProfileColorRaw: String
    let imageURL: String
    let emotion: EmotionState
    let caption: String
    var likeCount: Int
    var commentCount: Int
    let createdAt: Date
    var isLiked: Bool = false

    var userProfileColor: ProfileColor {
        ProfileColor(rawValue: userProfileColorRaw) ?? .blue
    }

    var dict: [String: Any] {
        [
            "userId": userId,
            "userDisplayName": userDisplayName,
            "userAvatarEmoji": userAvatarEmoji,
            "userProfileColorRaw": userProfileColorRaw,
            "imageURL": imageURL,
            "emotion": emotion.rawValue,
            "caption": caption,
            "likeCount": likeCount,
            "commentCount": commentCount,
            "createdAt": createdAt
        ]
    }

    static func from(_ dict: [String: Any], id: String) -> Post? {
        guard
            let userId = dict["userId"] as? String,
            let userDisplayName = dict["userDisplayName"] as? String,
            let userAvatarEmoji = dict["userAvatarEmoji"] as? String,
            let userProfileColorRaw = dict["userProfileColorRaw"] as? String,
            let imageURL = dict["imageURL"] as? String,
            let emotionRaw = dict["emotion"] as? String,
            let emotion = EmotionState(rawValue: emotionRaw)
        else { return nil }

        return Post(
            id: id,
            userId: userId,
            userDisplayName: userDisplayName,
            userAvatarEmoji: userAvatarEmoji,
            userProfileColorRaw: userProfileColorRaw,
            imageURL: imageURL,
            emotion: emotion,
            caption: dict["caption"] as? String ?? "",
            likeCount: dict["likeCount"] as? Int ?? 0,
            commentCount: dict["commentCount"] as? Int ?? 0,
            createdAt: (dict["createdAt"] as? Date) ?? Date()
        )
    }
}

// MARK: - Bildirim

struct AppNotification: Identifiable {
    let id: String
    let type: String          // "follow" | "like" | "comment"
    let fromUserId: String
    let fromUserName: String
    let fromUserAvatar: String
    let fromUserColor: String
    let postId: String?
    let postImageUrl: String?
    var read: Bool
    let createdAt: Date

    static func from(_ dict: [String: Any], id: String) -> AppNotification? {
        guard
            let type         = dict["type"]         as? String,
            let fromUserId   = dict["fromUserId"]   as? String,
            let fromUserName = dict["fromUserName"] as? String,
            let fromUserAvatar = dict["fromUserAvatar"] as? String,
            let fromUserColor  = dict["fromUserColor"]  as? String
        else { return nil }

        let ts = dict["createdAt"] as? Date ?? Date()

        return AppNotification(
            id: id,
            type: type,
            fromUserId: fromUserId,
            fromUserName: fromUserName,
            fromUserAvatar: fromUserAvatar,
            fromUserColor: fromUserColor,
            postId: dict["postId"] as? String,
            postImageUrl: dict["postImageUrl"] as? String,
            read: dict["read"] as? Bool ?? false,
            createdAt: ts
        )
    }
}

struct Comment: Identifiable {
    let id: String
    let userId: String
    let userDisplayName: String
    let userAvatarEmoji: String
    let text: String
    let createdAt: Date

    var dict: [String: Any] {
        [
            "userId": userId,
            "userDisplayName": userDisplayName,
            "userAvatarEmoji": userAvatarEmoji,
            "text": text,
            "createdAt": createdAt
        ]
    }

    static func from(_ dict: [String: Any], id: String) -> Comment? {
        guard
            let userId = dict["userId"] as? String,
            let userDisplayName = dict["userDisplayName"] as? String,
            let userAvatarEmoji = dict["userAvatarEmoji"] as? String,
            let text = dict["text"] as? String
        else { return nil }

        return Comment(
            id: id,
            userId: userId,
            userDisplayName: userDisplayName,
            userAvatarEmoji: userAvatarEmoji,
            text: text,
            createdAt: (dict["createdAt"] as? Date) ?? Date()
        )
    }
}
