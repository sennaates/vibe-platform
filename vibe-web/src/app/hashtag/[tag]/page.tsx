"use client"

import { useEffect, useRef, useState } from "react"
import { useParams } from "next/navigation"
import {
  collection,
  query,
  where,
  orderBy,
  limit,
  getDocs,
  startAfter,
  QueryDocumentSnapshot,
  doc,
  getDoc,
} from "firebase/firestore"
import { db } from "@/lib/firebase"
import { PostCard } from "@/components/feed/PostCard"
import { Hash, Loader2 } from "lucide-react"
import { normalizePost, type NormalizedPost } from "@/types"
import { useAuth } from "@/hooks/useAuth"

const PAGE_SIZE = 12

async function enrichLikes(posts: NormalizedPost[], userId: string): Promise<Set<string>> {
  const likedSet = new Set<string>()
  await Promise.all(posts.map(async p => {
    const s = await getDoc(doc(db, "posts", p.id, "likes", userId))
    if (s.exists()) likedSet.add(p.id)
  }))
  return likedSet
}

export default function HashtagPage() {
  const params = useParams()
  const rawTag = params.tag as string
  const tag = decodeURIComponent(rawTag).toLowerCase()
  const { user } = useAuth()

  const [posts, setPosts] = useState<NormalizedPost[]>([])
  const [liked, setLiked] = useState<Set<string>>(new Set())
  const [loading, setLoading] = useState(true)
  const [hasMore, setHasMore] = useState(true)
  const lastDocRef = useRef<QueryDocumentSnapshot | null>(null)
  const sentinelRef = useRef<HTMLDivElement>(null)
  const loadingMore = useRef(false)

  async function loadPosts(reset = false) {
    if (loadingMore.current && !reset) return
    loadingMore.current = true

    const constraints: Parameters<typeof query>[1][] = [
      where("tags", "array-contains", tag),
      orderBy("createdAt", "desc"),
      limit(PAGE_SIZE),
    ]
    if (!reset && lastDocRef.current) {
      constraints.push(startAfter(lastDocRef.current))
    }

    let snap
    let usedFallback = false
    try {
      snap = await getDocs(query(collection(db, "posts"), ...constraints))
    } catch (e) {
      console.warn("Hashtag query with orderBy failed (probably missing index). Falling back to non-ordered query.", e)
      usedFallback = true
      try {
        const fallbackConstraints: Parameters<typeof query>[1][] = [
          where("tags", "array-contains", tag),
          limit(PAGE_SIZE * 2),
        ]
        if (!reset && lastDocRef.current) {
          fallbackConstraints.push(startAfter(lastDocRef.current))
        }
        snap = await getDocs(query(collection(db, "posts"), ...fallbackConstraints))
      } catch (fallbackErr) {
        console.error("Fallback query failed as well:", fallbackErr)
        setPosts([])
        loadingMore.current = false
        return
      }
    }

    const newPosts = snap.docs.map(d => (normalizePost({ id: d.id, ...d.data() } as Parameters<typeof normalizePost>[0])))
    
    if (usedFallback) {
      newPosts.sort((a, b) => {
        const timeA = a.createdAt?.toMillis?.() ?? (a.createdAt?.seconds ? a.createdAt.seconds * 1000 : 0)
        const timeB = b.createdAt?.toMillis?.() ?? (b.createdAt?.seconds ? b.createdAt.seconds * 1000 : 0)
        return timeB - timeA
      })
    }

    if (reset) {
      setPosts(newPosts)
      if (user) {
        const ls = await enrichLikes(newPosts, user.uid)
        setLiked(ls)
      }
    } else {
      setPosts(prev => [...prev, ...newPosts])
      if (user) {
        const ls = await enrichLikes(newPosts, user.uid)
        setLiked(prev => new Set([...prev, ...ls]))
      }
    }

    lastDocRef.current = snap.docs[snap.docs.length - 1] ?? null
    setHasMore(snap.docs.length === PAGE_SIZE)
    loadingMore.current = false
  }

  useEffect(() => {
    lastDocRef.current = null
    const timer = setTimeout(() => {
      setLoading(true)
      loadPosts(true).finally(() => setLoading(false))
    }, 0)
    return () => clearTimeout(timer)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tag])

  // Infinite scroll
  useEffect(() => {
    const el = sentinelRef.current
    if (!el) return
    const obs = new IntersectionObserver(
      entries => {
        if (entries[0].isIntersecting && hasMore && !loadingMore.current) {
          loadPosts()
        }
      },
      { rootMargin: "200px" }
    )
    obs.observe(el)
    return () => obs.disconnect()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hasMore])

  return (
    <main className="max-w-2xl mx-auto px-4 py-8">
      {/* Header */}
      <div className="flex items-center gap-3 mb-8">
        <span className="w-11 h-11 rounded-[14px] bg-accent/10 flex items-center justify-center">
          <Hash size={22} className="text-accent" />
        </span>
        <div>
          <h1 className="text-2xl font-bold text-ink">#{tag}</h1>
          {!loading && (
            <p className="text-sm text-ink-subtle mt-0.5">
              {posts.length > 0
                ? `${posts.length}${hasMore ? "+" : ""} gönderi`
                : "Henüz gönderi yok"}
            </p>
          )}
        </div>
      </div>

      {/* Posts */}
      {loading ? (
        <div className="flex justify-center py-16">
          <Loader2 size={28} className="animate-spin text-ink-subtle" />
        </div>
      ) : posts.length === 0 ? (
        <div className="text-center py-20 text-ink-subtle">
          <Hash size={40} className="mx-auto mb-4 opacity-30" />
          <p className="font-medium">{"Bu hashtag'e ait gönderi bulunamadı."}</p>
        </div>
      ) : (
        <div className="flex flex-col gap-4">
          {posts.map(post => (
            <PostCard key={post.id} post={post} isLiked={liked.has(post.id)} />
          ))}
        </div>
      )}

      {/* Infinite scroll sentinel */}
      <div ref={sentinelRef} className="py-6 flex justify-center">
        {!loading && hasMore && posts.length > 0 && (
          <Loader2 size={20} className="animate-spin text-ink-subtle" />
        )}
        {!loading && !hasMore && posts.length > 0 && (
          <p className="text-xs text-ink-subtle">Tüm gönderiler yüklendi</p>
        )}
      </div>
    </main>
  )
}
