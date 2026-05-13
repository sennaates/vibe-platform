import Foundation
import SwiftUI

// MARK: - SocialUser

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

    /// Firestore'a yazılan canonical alanlar (web ile uyumlu)
    var dict: [String: Any] {
        [
            "displayName":    displayName,
            "avatarEmoji":    avatarEmoji,
            "profileColor":   profileColorRaw,   // web: profileColor
            "bio":            bio,
            "followersCount": followerCount,      // web: followersCount
            "followingCount": followingCount,
            "postsCount":     postCount,          // web: postsCount
            "createdAt":      createdAt
        ]
    }

    static func from(_ dict: [String: Any], id: String) -> SocialUser? {
        guard let displayName = dict["displayName"] as? String else { return nil }

        let avatarEmoji     = dict["avatarEmoji"]     as? String ?? "🎨"
        // web: profileColor, ios (eski): profileColorRaw
        let profileColorRaw = dict["profileColor"]    as? String
                           ?? dict["profileColorRaw"] as? String
                           ?? ProfileColor.blue.rawValue
        // web: followersCount, ios (eski): followerCount
        let followerCount   = dict["followersCount"]  as? Int
                           ?? dict["followerCount"]   as? Int
                           ?? 0
        let followingCount  = dict["followingCount"]  as? Int ?? 0
        // web: postsCount, ios (eski): postCount
        let postCount       = dict["postsCount"]      as? Int
                           ?? dict["postCount"]       as? Int
                           ?? 0
        let createdAt: Date = (dict["createdAt"] as? Date) ?? Date()

        return SocialUser(
            id:             id,
            displayName:    displayName,
            avatarEmoji:    avatarEmoji,
            profileColorRaw: profileColorRaw,
            bio:            dict["bio"] as? String ?? "",
            followerCount:  followerCount,
            followingCount: followingCount,
            postCount:      postCount,
            createdAt:      createdAt
        )
    }
}

// MARK: - Post

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
    let bpm: Int
    let caption: String
    var likeCount: Int
    var commentCount: Int
    let createdAt: Date
    var isLiked: Bool = false

    var userProfileColor: ProfileColor {
        ProfileColor(rawValue: userProfileColorRaw) ?? .blue
    }

    /// Extracts lowercase hashtag strings from caption (e.g. "#mutlu" → ["mutlu"])
    var extractedTags: [String] {
        let pattern = #"#([\wÀ-ɏЀ-ӿ]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(caption.startIndex..., in: caption)
        return regex.matches(in: caption, range: range).compactMap { match in
            guard let r = Range(match.range(at: 1), in: caption) else { return nil }
            return String(caption[r]).lowercased()
        }
    }

    /// Firestore'a yazılan canonical alanlar (web ile uyumlu field adları)
    var dict: [String: Any] {
        var d: [String: Any] = [
            "userId":           userId,
            "userName":         userDisplayName,   // web canonical
            "userDisplayName":  userDisplayName,   // ios backward compat
            "userAvatar":       userAvatarEmoji,   // web canonical
            "userAvatarEmoji":  userAvatarEmoji,   // ios backward compat
            "userColor":        userProfileColorRaw, // web canonical
            "userProfileColorRaw": userProfileColorRaw, // ios backward compat
            "imageUrl":         imageURL,           // web canonical
            "imageURL":         imageURL,           // ios backward compat
            "emotion":          emotion.rawValue,
            "bpm":              bpm,
            "caption":          caption,
            "likesCount":       likeCount,          // web canonical
            "likeCount":        likeCount,          // ios backward compat
            "commentsCount":    commentCount,        // web canonical
            "commentCount":     commentCount,        // ios backward compat
            "createdAt":        createdAt
        ]
        let tags = extractedTags
        if !tags.isEmpty { d["tags"] = tags }
        return d
    }

    static func from(_ dict: [String: Any], id: String) -> Post? {
        // userId zorunlu
        guard let userId = dict["userId"] as? String else { return nil }

        // displayName — web: userName, ios: userDisplayName
        let userDisplayName = dict["userDisplayName"] as? String
                           ?? dict["userName"]        as? String
                           ?? "Kullanıcı"

        // avatar — web: userAvatar, ios: userAvatarEmoji
        let userAvatarEmoji = dict["userAvatarEmoji"] as? String
                           ?? dict["userAvatar"]      as? String
                           ?? "🎨"

        // profileColor — web: userColor, ios: userProfileColorRaw
        let userProfileColorRaw = dict["userProfileColorRaw"] as? String
                               ?? dict["userColor"]            as? String
                               ?? ProfileColor.blue.rawValue

        // imageURL — web: imageUrl, ios: imageURL
        let imageURL = dict["imageURL"]  as? String
                    ?? dict["imageUrl"]  as? String
                    ?? ""

        // emotion — ios rawValue ("calm") veya web format ("Sakin 😌" ilk kelime)
        let emotionRaw = dict["emotion"] as? String ?? ""
        let emotion = EmotionState(rawValue: emotionRaw)
                   ?? EmotionState.from(displayName: emotionRaw.components(separatedBy: " ").first ?? "")
                   ?? .unknown

        // sayaçlar — web: likesCount/commentsCount, ios: likeCount/commentCount
        let likeCount    = dict["likesCount"]    as? Int ?? dict["likeCount"]    as? Int ?? 0
        let commentCount = dict["commentsCount"] as? Int ?? dict["commentCount"] as? Int ?? 0

        return Post(
            id:                  id,
            userId:              userId,
            userDisplayName:     userDisplayName,
            userAvatarEmoji:     userAvatarEmoji,
            userProfileColorRaw: userProfileColorRaw,
            imageURL:            imageURL,
            emotion:             emotion,
            bpm:                 dict["bpm"] as? Int ?? 72,
            caption:             dict["caption"] as? String ?? "",
            likeCount:           likeCount,
            commentCount:        commentCount,
            createdAt:           (dict["createdAt"] as? Date) ?? Date()
        )
    }
}

// MARK: - Comment

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
    var replyToId: String?
    var replyToName: String?

    var dict: [String: Any] {
        var d: [String: Any] = [
            "userId":          userId,
            "userDisplayName": userDisplayName,
            "userName":        userDisplayName, // web canonical
            "userAvatarEmoji": userAvatarEmoji,
            "userAvatar":      userAvatarEmoji, // web canonical
            "text":            text,
            "createdAt":       createdAt
        ]
        if let rId   = replyToId   { d["replyToId"]   = rId }
        if let rName = replyToName { d["replyToName"] = rName }
        return d
    }

    static func from(_ dict: [String: Any], id: String) -> Comment? {
        guard
            let userId = dict["userId"] as? String,
            let text   = dict["text"]   as? String
        else { return nil }

        let userDisplayName = dict["userDisplayName"] as? String
                           ?? dict["userName"]        as? String
                           ?? "Kullanıcı"
        let userAvatarEmoji = dict["userAvatarEmoji"] as? String
                           ?? dict["userAvatar"]      as? String
                           ?? "🎨"

        return Comment(
            id:              id,
            userId:          userId,
            userDisplayName: userDisplayName,
            userAvatarEmoji: userAvatarEmoji,
            text:            text,
            createdAt:       (dict["createdAt"] as? Date) ?? Date(),
            replyToId:       dict["replyToId"]   as? String,
            replyToName:     dict["replyToName"] as? String
        )
    }
}
