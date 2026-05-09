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
  // notification preferences (default true if absent)
  notifFollows?: boolean
  notifLikes?: boolean
  notifComments?: boolean
  // privacy
  isPrivate?: boolean
}

export interface Post {
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
  userName: string
  userAvatar: string
  userColor: string
  text: string
  createdAt: Timestamp
}

export interface EmotionState {
  label: string
  emoji: string
  valence: number   // -1..1
  arousal: number   // -1..1
}
