/**
 * Vibe — Firebase Cloud Functions
 *
 * Kurulum:
 *   cd functions && npm install
 *   npm run deploy
 *
 * Çalışma mantığı:
 *   notifications/{uid}/items/{notifId} belgesine her yeni yazıda,
 *   hedef kullanıcının pushToken'ı Firestore'dan okunur ve
 *   Firebase Admin SDK üzerinden FCM push gönderilir.
 */

import * as admin from "firebase-admin"
import { onDocumentCreated } from "firebase-functions/v2/firestore"

admin.initializeApp()

const db = admin.firestore()
const messaging = admin.messaging()

// ── Bildirim yazar → push gönder ──────────────────────────────────────────────

export const sendPushOnNotification = onDocumentCreated(
  "notifications/{uid}/items/{notifId}",
  async (event) => {
    const uid    = event.params.uid
    const notif  = event.data?.data()

    if (!notif) return

    // Hedef kullanıcının push token'ını al
    const userSnap = await db.collection("users").doc(uid).get()
    const token    = userSnap.data()?.pushToken as string | undefined
    if (!token) return

    // Bildirim içeriği
    const titles: Record<string, string> = {
      like:    "Çizimine beğeni geldi ❤️",
      comment: "Çizimine yorum yapıldı 💬",
      follow:  "Seni biri takip etmeye başladı 🎉",
    }
    const bodies: Record<string, string> = {
      like:    `${notif.fromUserName} çizimini beğendi`,
      comment: `${notif.fromUserName}: "${String(notif.commentText ?? "").slice(0, 60)}"`,
      follow:  `${notif.fromUserName} seni takip ediyor`,
    }

    const type  = notif.type as string
    const title = titles[type] ?? "Vibe"
    const body  = bodies[type] ?? `${notif.fromUserName} bir işlem yaptı`

    try {
      await messaging.send({
        token,
        notification: { title, body },
        data: {
          type,
          fromUserId: notif.fromUserId ?? "",
          postId:     notif.postId     ?? "",
          notifId:    event.params.notifId,
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              "content-available": 1,
            },
          },
        },
        android: {
          notification: {
            sound: "default",
            channelId: "vibe_notifications",
          },
        },
        webpush: {
          notification: {
            icon: "/icon-192x192.png",
            badge: "/icon-72x72.png",
            tag: type,
            renotify: true,
          },
          fcmOptions: {
            link: type === "follow"
              ? `/profile/${notif.fromUserId}`
              : `/post/${notif.postId}`,
          },
        },
      })
      console.log(`✅ Push gönderildi → ${uid} (${type})`)
    } catch (err) {
      console.error("Push gönderilemedi:", err)
    }
  }
)
