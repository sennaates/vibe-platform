import { Timestamp } from "firebase/firestore"

export interface SocialUser {
  uid: string
  email: string
  displayName: string
  avatarEmoji: string
  bio: string
  profileColor: string
  followersCount: number
  followingCount: number
  postsCount: number
  createdAt: Timestamp
  notifFollows?: boolean
  notifLikes?: boolean
  notifComments?: boolean
  isPrivate?: boolean
}

/**
 * Firestore'daki Post belgesi.
 * Web canonical alanları zorunlu; iOS eski alanları optional fallback olarak eklendi.
 * normalizePost() her ikisini de okuyarak normalize eder.
 */
export interface Post {
  id: string
  userId: string
  // canonical (web)
  userName?: string
  userAvatar?: string
  userColor?: string
  imageUrl?: string
  likesCount?: number
  commentsCount?: number
  // ios backward compat
  userDisplayName?: string
  userAvatarEmoji?: string
  userProfileColorRaw?: string
  imageURL?: string
  likeCount?: number
  commentCount?: number
  // shared
  emotion: string
  bpm: number
  caption: string
  tags?: string[]
  createdAt: Timestamp
}

/** Post'u normalize eder — hem web hem iOS kaynaklı dökümanları yönetir */
export function normalizePost(raw: Post): NormalizedPost {
  return {
    ...raw,
    userName:     raw.userName     ?? raw.userDisplayName ?? "Kullanıcı",
    userAvatar:   raw.userAvatar   ?? raw.userAvatarEmoji ?? "🎨",
    userColor:    raw.userColor    ?? raw.userProfileColorRaw ?? "blue",
    imageUrl:     raw.imageUrl     ?? raw.imageURL ?? "",
    likesCount:   raw.likesCount   ?? raw.likeCount    ?? 0,
    commentsCount: raw.commentsCount ?? raw.commentCount ?? 0,
  }
}

export interface NormalizedPost {
  id: string
  userId: string
  userName: string
  userAvatar: string
  userColor: string
  imageUrl: string
  emotion: string
  bpm: number
  caption: string
  tags?: string[]
  likesCount: number
  commentsCount: number
  createdAt: Timestamp
}

export interface Comment {
  id: string
  userId: string
  // canonical (web)
  userName?: string
  userAvatar?: string
  // ios backward compat
  userDisplayName?: string
  userAvatarEmoji?: string
  text: string
  replyToId?: string | null
  replyToName?: string | null
  createdAt: Timestamp
}

export interface EmotionState {
  label: string
  emoji: string
  valence: number
  arousal: number
}
