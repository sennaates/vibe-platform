/**
 * Firebase Cloud Messaging — Web Push
 *
 * Kurulum:
 * 1. Firebase Console → Project Settings → Cloud Messaging → Web Push certificates
 *    "Generate key pair" → VAPID key'i .env.local'a ekle:
 *    NEXT_PUBLIC_FIREBASE_VAPID_KEY=<buraya_yaz>
 *
 * 2. public/firebase-messaging-sw.js dosyası Service Worker olarak gereklidir
 *    (bu dosyayı aşağıdaki içerikle oluştur)
 *
 * 3. Kullanımı: settings sayfasından requestPushPermission() çağır
 */

import { getMessaging, getToken, onMessage, type Messaging } from "firebase/messaging"
import { doc, updateDoc } from "firebase/firestore"
import app, { db } from "./firebase"

const VAPID_KEY = process.env.NEXT_PUBLIC_FIREBASE_VAPID_KEY ?? ""

let messaging: Messaging | null = null

function getMessagingInstance(): Messaging | null {
  if (typeof window === "undefined") return null
  if (!messaging) {
    try {
      messaging = getMessaging(app)
    } catch {
      console.warn("FCM başlatılamadı")
      return null
    }
  }
  return messaging
}

/** Bildirim izni iste ve FCM token'ı Firestore'a kaydet */
export async function requestPushPermission(userId: string): Promise<boolean> {
  const m = getMessagingInstance()
  if (!m) return false

  try {
    const permission = await Notification.requestPermission()
    if (permission !== "granted") return false

    const token = await getToken(m, { vapidKey: VAPID_KEY })
    if (!token) return false

    await updateDoc(doc(db, "users", userId), {
      pushToken: token,
      pushTokenType: "fcm-web",
    })

    console.log("✅ FCM token kaydedildi")
    return true
  } catch (err) {
    console.error("Push izni alınamadı:", err)
    return false
  }
}

/** Uygulama açıkken gelen bildirimleri dinle */
export function listenForegroundMessages(
  callback: (title: string, body: string, data?: Record<string, string>) => void
) {
  const m = getMessagingInstance()
  if (!m) return () => {}

  return onMessage(m, (payload) => {
    const title = payload.notification?.title ?? "Vibe"
    const body  = payload.notification?.body  ?? ""
    const data  = payload.data as Record<string, string> | undefined
    callback(title, body, data)
  })
}
