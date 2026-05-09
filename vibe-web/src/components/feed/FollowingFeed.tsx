"use client"

import { useEffect, useRef, useState } from "react"
import Link from "next/link"
import {
  collection, query, where, getDocs, orderBy, limit,
  startAfter, doc, getDoc, QueryDocumentSnapshot
} from "firebase/firestore"
import { db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { PostCard } from "./PostCard"
import { Loader2 } from "lucide-react"
import type { Post } from "@/types"

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

export function FollowingFeed() {
  const { user } = useAuth()
  const [posts, setPosts]           = useState<Post[]>([])
  const [liked, setLiked]           = useState<Set<string>>(new Set())
  const [loading, setLoading]       = useState(true)
  const [hasMore, setHasMore]       = useState(true)
  const [noFollows, setNoFollows]   = useState(false)

  const followedIdsRef = useRef<string[]>([])
  const lastDocRef     = useRef<QueryDocumentSnapshot | null>(null)
  const loadingMore    = useRef(false)
  const sentinelRef    = useRef<HTMLDivElement>(null)

  async function loadMore() {
    if (loadingMore.current || !hasMore) return
    const ids = followedIdsRef.current
    if (ids.length === 0) return
    loadingMore.current = true

    // Firestore "in" supports up to 30; chunk if needed
    const chunks: string[][] = []
    for (let i = 0; i < ids.length; i += 30) chunks.push(ids.slice(i, i + 30))

    // We only paginate on first chunk for simplicity (most users follow < 30)
    const constraints: Parameters<typeof query>[1][] = [
      where("userId", "in", chunks[0]),
      orderBy("createdAt", "desc"),
      limit(PAGE_SIZE),
    ]
    if (lastDocRef.current) constraints.push(startAfter(lastDocRef.current))

    const snap = await getDocs(query(collection(db, "posts"), ...constraints))
    const newPosts = snap.docs.map(d => ({ id: d.id, ...d.data() } as Post))

    // Check liked status for new posts
    const uid = user!.uid
    const likedSet = new Set(liked)
    await Promise.all(
      newPosts.map(async p => {
        const s = await getDoc(doc(db, "posts", p.id, "likes", uid))
        if (s.exists()) likedSet.add(p.id)
      })
    )
    setLiked(likedSet)
    setPosts(prev => [...prev, ...newPosts])
    lastDocRef.current = snap.docs[snap.docs.length - 1] ?? null
    setHasMore(snap.docs.length === PAGE_SIZE)
    loadingMore.current = false
  }

  useEffect(() => {
    if (!user) { setLoading(false); return }

    async function init() {
      // Fetch followed user IDs
      const followSnap = await getDocs(
        query(collection(db, "follows"), where("followerId", "==", user!.uid), limit(30))
      )
      const ids = followSnap.docs.map(d => d.data().followedId as string)
      followedIdsRef.current = ids

      if (ids.length === 0) { setNoFollows(true); setLoading(false); return }

      await loadMore()
      setLoading(false)
    }

    init()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user])

  // Infinite scroll observer
  useEffect(() => {
    const el = sentinelRef.current
    if (!el) return
    const obs = new IntersectionObserver(
      entries => {
        if (entries[0].isIntersecting && hasMore && !loadingMore.current) loadMore()
      },
      { rootMargin: "200px" }
    )
    obs.observe(el)
    return () => obs.disconnect()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hasMore, loading])

  if (loading) {
    return (
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-5">
        {[...Array(3)].map((_, i) => <PostSkeleton key={i} />)}
      </div>
    )
  }

  if (!user) {
    return (
      <div className="flex flex-col items-center py-24 text-center gap-3">
        <span className="text-5xl">🔒</span>
        <p className="text-ink font-semibold">Takip feed&apos;ini görmek için giriş yap</p>
        <Link href="/auth" className="mt-1 px-5 py-2.5 bg-accent text-white rounded-[14px] text-sm font-semibold">
          Giriş Yap
        </Link>
      </div>
    )
  }

  if (noFollows) {
    return (
      <div className="flex flex-col items-center py-24 text-center gap-3">
        <span className="text-5xl">👥</span>
        <p className="text-ink font-semibold text-lg">Henüz takip ettiğin biri yok</p>
        <p className="text-sm text-ink-muted max-w-xs">
          Birini takip ettiğinde çizimleri burada belirecek
        </p>
        <Link
          href="/search"
          className="mt-2 px-5 py-2.5 bg-accent text-white rounded-[14px] text-sm font-semibold shadow-sm hover:bg-accent-hover transition-colors"
        >
          Kullanıcı Ara
        </Link>
      </div>
    )
  }

  return (
    <>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-5">
        {posts.map(post => (
          <PostCard key={post.id} post={post} isLiked={liked.has(post.id)} />
        ))}
      </div>

      {/* Infinite scroll sentinel */}
      <div ref={sentinelRef} className="py-6 flex justify-center">
        {hasMore && posts.length > 0 && (
          <Loader2 size={20} className="animate-spin text-ink-subtle" />
        )}
        {!hasMore && posts.length > 0 && (
          <p className="text-xs text-ink-subtle">Tüm gönderiler yüklendi</p>
        )}
      </div>
    </>
  )
}
