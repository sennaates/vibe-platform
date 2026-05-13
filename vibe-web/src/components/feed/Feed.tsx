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
    const s = await getDoc(doc(db, "posts", p.id, "likes", userId))
    if (s.exists()) likedSet.add(p.id)
  }))
  return likedSet
}

export function Feed() {
  const { user } = useAuth()
  const [sort, setSort]             = useState<FeedSort>("recent")
  const [posts, setPosts]           = useState<NormalizedPost[]>([])
  const [liked, setLiked]           = useState<Set<string>>(new Set())
  const [loading, setLoading]       = useState(true)
  const [loadingMore, setLoadingMore] = useState(false)
  const [hasMore, setHasMore]       = useState(true)
  const lastDocRef                  = useRef<QueryDocumentSnapshot<DocumentData> | null>(null)
  const sentinelRef                 = useRef<HTMLDivElement>(null)
  const unsubRef                    = useRef<(() => void) | null>(null)

  // Reset + ilk yükleme
  useEffect(() => {
    unsubRef.current?.()
    unsubRef.current = null
    setLoading(true)
    setPosts([])
    setLiked(new Set())
    setHasMore(true)
    lastDocRef.current = null

    if (sort === "recent") {
      // Realtime ilk sayfa
      const q = query(collection(db, "posts"), orderBy("createdAt", "desc"), limit(PAGE_SIZE))
      const unsub = onSnapshot(q, async snap => {
        const fetched = snap.docs.map(d => (normalizePost({ id: d.id, ...d.data() } as Parameters<typeof normalizePost>[0])))
        lastDocRef.current = snap.docs[snap.docs.length - 1] ?? null
        setHasMore(snap.docs.length === PAGE_SIZE)
        setPosts(fetched)
        if (user) {
          const ls = await enrichLikes(fetched, user.uid)
          setLiked(ls)
        }
        setLoading(false)
      })
      unsubRef.current = unsub
      return () => { unsub(); unsubRef.current = null }
    } else {
      const q = query(collection(db, "posts"), orderBy("likesCount", "desc"), limit(PAGE_SIZE))
      getDocs(q).then(async snap => {
        const fetched = snap.docs.map(d => (normalizePost({ id: d.id, ...d.data() } as Parameters<typeof normalizePost>[0])))
        lastDocRef.current = snap.docs[snap.docs.length - 1] ?? null
        setHasMore(snap.docs.length === PAGE_SIZE)
        setPosts(fetched)
        if (user) {
          const ls = await enrichLikes(fetched, user.uid)
          setLiked(ls)
        }
        setLoading(false)
      })
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sort])

  const loadMore = useCallback(async () => {
    if (loadingMore || !hasMore || !lastDocRef.current) return
    setLoadingMore(true)
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
    setPosts(prev => [...prev, ...fetched])
    setLoadingMore(false)
  }, [loadingMore, hasMore, sort, user])

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
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-5">
          {[...Array(6)].map((_, i) => <PostSkeleton key={i} />)}
        </div>
      </section>
    )
  }

  if (posts.length === 0) {
    return (
      <section>
        {sortBar}
        <div className="flex flex-col items-center justify-center py-24 text-center">
          <span className="text-6xl mb-4 block">🎨</span>
          <p className="text-ink font-semibold text-lg">Henüz paylaşım yok</p>
          <p className="text-ink-muted text-sm mt-1.5">İlk çizimi paylaşan sen ol</p>
        </div>
      </section>
    )
  }

  return (
    <section>
      {sortBar}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-5">
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
