const CACHE = "vibe-v1"
const STATIC = ["/", "/offline.html", "/logo.png", "/manifest.json"]

// Install — cache static assets
self.addEventListener("install", e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(STATIC)).then(() => self.skipWaiting())
  )
})

// Activate — clean old caches
self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  )
})

// Fetch — network first, fallback to cache
self.addEventListener("fetch", e => {
  const { request } = e
  // Only handle GET
  if (request.method !== "GET") return
  // Skip Firebase / Cloudinary / analytics
  const url = new URL(request.url)
  if (
    url.hostname.includes("firestore.googleapis.com") ||
    url.hostname.includes("firebase") ||
    url.hostname.includes("cloudinary") ||
    url.hostname.includes("google-analytics") ||
    url.hostname.includes("fonts.googleapis") ||
    url.protocol === "chrome-extension:"
  ) return

  e.respondWith(
    fetch(request)
      .then(res => {
        // Cache successful same-origin responses
        if (res.ok && url.origin === self.location.origin) {
          const clone = res.clone()
          caches.open(CACHE).then(c => c.put(request, clone))
        }
        return res
      })
      .catch(() =>
        caches.match(request).then(cached =>
          cached ?? caches.match("/offline.html")
        )
      )
  )
})
