import { collection, addDoc, serverTimestamp } from "firebase/firestore"
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

/** Creates a notification for targetUserId. No-op if sender === target. */
export async function createNotification(data: NotificationData) {
  if (data.targetUserId === data.fromUserId) return
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
