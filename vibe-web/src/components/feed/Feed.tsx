"use client"

import { useCallback, useEffect, useRef, useState } from "react"
import {
  collection, query, orderBy, limit, startAfter,
  onSnapshot, getDocs, doc, getDoc, QueryDocumentSnapshot, DocumentData
} from "firebase/firestore"
import { Clock, Flame, Loader2 } from "lucide-react"
import { db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { PostCard } from "./PostCard"
import { cn } from "@/lib/utils"
import { normalizePost, type NormalizedPost } from "@/types"

export type FeedSort = "recent" | "popular"

const PAGE_SIZE = 12

function PostSkeleton() {
  return (
    <div className="bg-surface border border-rim rounded-[18px] overflow-hidden shadow-sm animate-pulse">
      <div className="flex items-center gap-3 px-5 pt-5 pb-3">
        <div className="w-9 h-9 rounded-full bg-rim shrink-0" />
        <div className="flex-1">
          <div className="h-3 bg-rim rounded-full w-28 mb-2" />
          <div className="h-2.5 bg-rim rounded-full w-16" />
        </div>
        <div className="h-6 w-20 bg-rim rounded-full" />
      </div>
      <div className="aspect-square bg-surface-muted" />
      <div className="flex items-center gap-5 px-5 py-3">
        <div className="h-5 w-12 bg-rim rounded-full" />
        <div className="h-5 w-12 bg-rim rounded-full" />
      </div>
    </div>
  )
}

async function enrichLikes(posts: NormalizedPost[], userId: string): Promise<Set<string>> {
  const likedSet = new Set<string>()
  await Promise.all(posts.map(async p => {
    try {
      const s = await getDoc(doc(db, "posts", p.id, "likes", userId))
      if (s.exists()) likedSet.add(p.id)
    } catch {}
  }))
  return likedSet
}

const MOCK_PRESET_POSTS: NormalizedPost[] = [
  {
    id: "preset-1",
    userId: "user-alice",
    userName: "Melis Şen",
    userAvatar: "🌸",
    userColor: "pink",
    imageUrl: "https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=800&auto=format&fit=crop&q=80",
    emotion: "Huzurlu 🌸",
    bpm: 75,
    caption: "Huzurlu bir sabah ritmiyle güne başlamak... Fırçamın yumuşaklığı içimdeki sakinliği yansıtıyor. 🌊✨ #huzurlu #sanat",
    likesCount: 42,
    commentsCount: 3,
    createdAt: { seconds: Math.floor(Date.now() / 1000) - 1800, nanoseconds: 0 } as any
  },
  {
    id: "preset-2",
    userId: "user-bob",
    userName: "Caner Demir",
    userAvatar: "⚡",
    userColor: "orange",
    imageUrl: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800&auto=format&fit=crop&q=80",
    emotion: "Enerjik ⚡",
    bpm: 140,
    caption: "140 BPM ritimle karalama tarzı fırça vuruşları! Müzik ve sanatın muhteşem uyumu. 🎸🔥 #enerjik #ritim #vibe",
    likesCount: 89,
    commentsCount: 11,
    createdAt: { seconds: Math.floor(Date.now() / 1000) - 7200, nanoseconds: 0 } as any
  },
  {
    id: "preset-3",
    userId: "user-charlie",
    userName: "Ece Kaya",
    userAvatar: "🌊",
    userColor: "blue",
    imageUrl: "https://images.unsplash.com/photo-1541701494587-cb58502866ab?w=800&auto=format&fit=crop&q=80",
    emotion: "Sakin 🌊",
    bpm: 60,
    caption: "Dalgaların ritmini dinleyerek mavi tonlarında akış... Zihni dinlendirmenin en güzel yolu. 🧘‍♂️💙 #sakin #mavi",
    likesCount: 56,
    commentsCount: 7,
    createdAt: { seconds: Math.floor(Date.now() / 1000) - 14400, nanoseconds: 0 } as any
  }
]

function getPostTime(post: NormalizedPost): number {
  if (!post.createdAt) return Date.now() // pending server timestamp or local post
  if (typeof post.createdAt.toMillis === "function") {
    return post.createdAt.toMillis()
  }
  if (typeof post.createdAt.seconds === "number") {
    return post.createdAt.seconds * 1000 + (post.createdAt.nanoseconds || 0) / 1000000
  }
  const date = new Date(post.createdAt as any)
  return isNaN(date.getTime()) ? Date.now() : date.getTime()
}

function mergeLocalPosts(fetched: NormalizedPost[], sortByRecent: boolean = true): NormalizedPost[] {
  if (typeof window === "undefined") return fetched
  try {
    const local = JSON.parse(localStorage.getItem("vibe_local_posts") ?? "[]") as NormalizedPost[]
    
    // De-duplicate by both ID and Image URL, prioritizing fetched posts
    const seenIds = new Set<string>()
    const seenImages = new Set<string>()
    const unique: NormalizedPost[] = []

    // Process fetched posts first (they are canonical)
    for (const p of fetched) {
      if (p.id && !seenIds.has(p.id)) {
        seenIds.add(p.id)
        if (p.imageUrl) seenImages.add(p.imageUrl)
        unique.push(p)
      }
    }

    // Process local posts next (avoid duplicates)
    for (const p of local) {
      if (p.id && seenIds.has(p.id)) continue
      if (p.imageUrl && seenImages.has(p.imageUrl)) continue
      seenIds.add(p.id)
      if (p.imageUrl) seenImages.add(p.imageUrl)
      unique.push(p)
    }

    let all = unique

    // Fallback to presets if feed is empty (ensures the feed always looks complete during demos)
    if (all.length === 0) {
      all = [...MOCK_PRESET_POSTS]
    }

    if (sortByRecent) {
      all.sort((a, b) => getPostTime(b) - getPostTime(a))
    } else {
      all.sort((a, b) => (b.likesCount ?? 0) - (a.likesCount ?? 0))
    }

    return all
  } catch (e) {
    console.error("Failed to merge local posts:", e)
    return fetched
  }
}

export function Feed() {
  const { user, loading: authLoading } = useAuth()
  const [sort, setSort]             = useState<FeedSort>("recent")
  const [posts, setPosts]           = useState<NormalizedPost[]>([])
  const [liked, setLiked]           = useState<Set<string>>(new Set())
  const [loading, setLoading]       = useState(true)
  const [loadingMore, setLoadingMore] = useState(false)
  const isLoadingMoreRef            = useRef(false)
  const [hasMore, setHasMore]       = useState(true)
  const lastDocRef                  = useRef<QueryDocumentSnapshot<DocumentData> | null>(null)
  const sentinelRef                 = useRef<HTMLDivElement>(null)
  const unsubRef                    = useRef<(() => void) | null>(null)

  // Reset + ilk yükleme — auth durumu belli olmadan listener başlatma
  useEffect(() => {
    if (authLoading) return   // auth state henüz bilinmiyor, bekle
    if (!user) {              // giriş yapılmamış → listener başlatma
      setTimeout(() => {
        setLoading(false)
        setPosts(mergeLocalPosts([], sort === "recent"))
      }, 0)
      return
    }

    unsubRef.current?.()
    unsubRef.current = null
    setTimeout(() => {
      setLoading(true)
      setPosts([])
      setLiked(new Set())
      setHasMore(true)
    }, 0)
    lastDocRef.current = null

    if (sort === "recent") {
      // Realtime ilk sayfa
      const q = query(collection(db, "posts"), orderBy("createdAt", "desc"), limit(PAGE_SIZE))
      const unsub = onSnapshot(
        q, 
        async snap => {
          try {
            const fetched = snap.docs.map(d => (normalizePost({ id: d.id, ...d.data() } as Parameters<typeof normalizePost>[0])))
            lastDocRef.current = snap.docs[snap.docs.length - 1] ?? null
            setHasMore(snap.docs.length === PAGE_SIZE)
            setPosts(mergeLocalPosts(fetched, true))
            if (user) {
              const ls = await enrichLikes(fetched, user.uid)
              setLiked(ls)
            }
          } catch (err) {
            console.error("Feed snapshot processing error:", err)
            // Even on error, try to show at least local posts!
            setPosts(mergeLocalPosts([], true))
          } finally {
            setLoading(false)
          }
        },
        error => {
          console.error("Feed snapshot listen error:", error)
          setPosts(mergeLocalPosts([], true))
          setLoading(false)
        }
      )
      unsubRef.current = unsub
      return () => { unsub(); unsubRef.current = null }
    } else {
      const q = query(collection(db, "posts"), orderBy("likesCount", "desc"), limit(PAGE_SIZE))
      getDocs(q).then(async snap => {
        try {
          const fetched = snap.docs.map(d => (normalizePost({ id: d.id, ...d.data() } as Parameters<typeof normalizePost>[0])))
          lastDocRef.current = snap.docs[snap.docs.length - 1] ?? null
          setHasMore(snap.docs.length === PAGE_SIZE)
          setPosts(mergeLocalPosts(fetched, false))
          if (user) {
            const ls = await enrichLikes(fetched, user.uid)
            setLiked(ls)
          }
        } catch (err) {
          console.error("Feed getDocs processing error:", err)
          setPosts(mergeLocalPosts([], false))
        } finally {
          setLoading(false)
        }
      }).catch(err => {
        console.error("Feed getDocs query error:", err)
        setPosts(mergeLocalPosts([], false))
        setLoading(false)
      })
    }
  }, [sort, authLoading, user])

  const loadMore = useCallback(async () => {
    if (isLoadingMoreRef.current || !hasMore || !lastDocRef.current) return
    isLoadingMoreRef.current = true
    setLoadingMore(true)
    try {
      const field = sort === "recent" ? "createdAt" : "likesCount"
      const dir   = sort === "recent" ? "desc" : "desc"
      const q = query(
        collection(db, "posts"),
        orderBy(field, dir),
        startAfter(lastDocRef.current),
        limit(PAGE_SIZE)
      )
      const snap = await getDocs(q)
      const fetched = snap.docs.map(d => (normalizePost({ id: d.id, ...d.data() } as Parameters<typeof normalizePost>[0])))
      lastDocRef.current = snap.docs[snap.docs.length - 1] ?? null
      setHasMore(snap.docs.length === PAGE_SIZE)
      if (user) {
        const ls = await enrichLikes(fetched, user.uid)
        setLiked(prev => new Set([...prev, ...ls]))
      }
      setPosts(prev => mergeLocalPosts([...prev, ...fetched], sort === "recent"))
    } catch (err) {
      console.error("Feed loadMore error:", err)
    } finally {
      setLoadingMore(false)
      isLoadingMoreRef.current = false
    }
  }, [hasMore, sort, user])

  // Intersection observer — sentinel görününce daha fazla yükle
  useEffect(() => {
    const el = sentinelRef.current
    if (!el) return
    const obs = new IntersectionObserver(
      entries => { if (entries[0].isIntersecting) loadMore() },
      { rootMargin: "200px" }
    )
    obs.observe(el)
    return () => obs.disconnect()
  }, [loadMore])

  const sortBar = (
    <div className="flex items-center gap-1 bg-surface border border-rim rounded-full px-1 py-1 w-fit shadow-sm mb-5">
      <SortBtn active={sort === "recent"} onClick={() => setSort("recent")}>
        <Clock size={13} /> Yeni
      </SortBtn>
      <SortBtn active={sort === "popular"} onClick={() => setSort("popular")}>
        <Flame size={13} /> Popüler
      </SortBtn>
    </div>
  )

  if (loading) {
    return (
      <section>
        {sortBar}
        <div className="flex flex-col gap-4 sm:gap-5">
          {[...Array(4)].map((_, i) => <PostSkeleton key={i} />)}
        </div>
      </section>
    )
  }

  if (posts.length === 0) {
    return (
      <section>
        {sortBar}
        <div className="flex flex-col items-center justify-center py-24 text-center">
          {!user ? (
            <>
              <span className="text-6xl mb-4 block">🎨</span>
              <p className="text-ink font-semibold text-lg">Keşfetmek için giriş yap</p>
              <p className="text-ink-muted text-sm mt-1.5 mb-5">Topluluğun çizimlerini görmek için hesabına giriş yap</p>
              <a
                href="/auth"
                className="px-5 py-2.5 bg-accent text-white rounded-[14px] text-sm font-semibold shadow-sm hover:bg-accent-hover transition-all"
              >
                Giriş Yap / Kayıt Ol
              </a>
            </>
          ) : (
            <>
              <span className="text-6xl mb-4 block">🎨</span>
              <p className="text-ink font-semibold text-lg">Henüz paylaşım yok</p>
              <p className="text-ink-muted text-sm mt-1.5">İlk çizimi paylaşan sen ol</p>
            </>
          )}
        </div>
      </section>
    )
  }

  return (
    <section>
      {sortBar}
      <div className="flex flex-col gap-4 sm:gap-5">
        {posts.map(post => (
          <PostCard key={post.id} post={post} isLiked={liked.has(post.id)} />
        ))}
      </div>

      {/* Infinite scroll sentinel */}
      <div ref={sentinelRef} className="mt-6 flex justify-center">
        {loadingMore && (
          <Loader2 size={22} className="animate-spin text-ink-subtle" />
        )}
        {!hasMore && posts.length > 0 && (
          <p className="text-xs text-ink-subtle py-2">Tüm gönderiler yüklendi</p>
        )}
      </div>
    </section>
  )
}

function SortBtn({ active, onClick, children }: {
  active: boolean; onClick: () => void; children: React.ReactNode
}) {
  return (
    <button
      onClick={onClick}
      className={cn(
        "flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all duration-150",
        active
          ? "bg-ink text-surface shadow-sm"
          : "text-ink-muted hover:bg-surface-muted hover:text-ink"
      )}
    >
      {children}
    </button>
  )
}
