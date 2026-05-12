// Firebase Messaging Service Worker
// Bu dosya public/ klasöründe olmalı (Next.js bunu /firebase-messaging-sw.js olarak sunar)

importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js")
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js")

// Firebase config'i buraya yapıştır (process.env SW'de çalışmaz)
firebase.initializeApp({
  apiKey:            self.__FIREBASE_API_KEY__            || "",
  authDomain:        self.__FIREBASE_AUTH_DOMAIN__        || "",
  projectId:         self.__FIREBASE_PROJECT_ID__         || "",
  storageBucket:     self.__FIREBASE_STORAGE_BUCKET__     || "",
  messagingSenderId: self.__FIREBASE_MESSAGING_SENDER_ID__ || "",
  appId:             self.__FIREBASE_APP_ID__             || "",
})

const messaging = firebase.messaging()

// Uygulama kapalıyken gelen bildirimler
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? "Vibe"
  const body  = payload.notification?.body  ?? ""
  const icon  = "/icon-192x192.png"

  self.registration.showNotification(title, {
    body,
    icon,
    data: payload.data,
    badge: "/icon-72x72.png",
    tag: payload.data?.type ?? "vibe",
    renotify: true,
  })
})

// Bildirime tıklandığında ilgili sayfayı aç
self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  const data = event.notification.data ?? {}
  let url = "/"
  if (data.type === "like" || data.type === "comment") {
    url = `/post/${data.postId}`
  } else if (data.type === "follow") {
    url = `/profile/${data.fromUserId}`
  }
  event.waitUntil(clients.openWindow(url))
})
