import { collection, addDoc, serverTimestamp, doc, getDoc } from "firebase/firestore"
import { db } from "./firebase"

export interface NotificationData {
  targetUserId: string
  type: "follow" | "like" | "comment"
  fromUserId: string
  fromUserName: string
  fromUserAvatar: string
  fromUserColor: string
  postId?: string
  postImageUrl?: string
  read?: boolean
}

const PREF_KEY: Record<NotificationData["type"], string> = {
  follow:  "notifFollows",
  like:    "notifLikes",
  comment: "notifComments",
}

/**
 * Creates a notification for targetUserId.
 * No-op if sender === target or if the target has disabled that notif type.
 */
export async function createNotification(data: NotificationData) {
  if (data.targetUserId === data.fromUserId) return

  // Check receiver's notification preference
  try {
    const userSnap = await getDoc(doc(db, "users", data.targetUserId))
    if (userSnap.exists()) {
      const prefs = userSnap.data()
      const prefKey = PREF_KEY[data.type]
      // If preference is explicitly false, skip
      if (prefs[prefKey] === false) return
    }
  } catch {
    // If we can't read prefs, proceed with creating notification
  }

  await addDoc(collection(db, "notifications", data.targetUserId, "items"), {
    type:           data.type,
    fromUserId:     data.fromUserId,
    fromUserName:   data.fromUserName,
    fromUserAvatar: data.fromUserAvatar,
    fromUserColor:  data.fromUserColor,
    ...(data.postId       ? { postId: data.postId }             : {}),
    ...(data.postImageUrl ? { postImageUrl: data.postImageUrl } : {}),
    read:      false,
    createdAt: serverTimestamp(),
  })
}
