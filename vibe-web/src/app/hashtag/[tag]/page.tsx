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
} from "firebase/firestore"
import { db } from "@/lib/firebase"
import { PostCard } from "@/components/feed/PostCard"
import { Hash, Loader2 } from "lucide-react"
import { normalizePost, type NormalizedPost } from "@/types"

const PAGE_SIZE = 12

export default function HashtagPage() {
  const params = useParams()
  const tag = (params.tag as string).toLowerCase()

  const [posts, setPosts] = useState<NormalizedPost[]>([])
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

    const snap = await getDocs(query(collection(db, "posts"), ...constraints))
    const newPosts = snap.docs.map(d => (normalizePost({ id: d.id, ...d.data() } as Parameters<typeof normalizePost>[0])))

    if (reset) {
      setPosts(newPosts)
    } else {
      setPosts(prev => [...prev, ...newPosts])
    }

    lastDocRef.current = snap.docs[snap.docs.length - 1] ?? null
    setHasMore(snap.docs.length === PAGE_SIZE)
    loadingMore.current = false
  }

  useEffect(() => {
    setLoading(true)
    lastDocRef.current = null
    loadPosts(true).finally(() => setLoading(false))
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
          <p className="font-medium">Bu hashtag'e ait gönderi bulunamadı.</p>
        </div>
      ) : (
        <div className="flex flex-col gap-4">
          {posts.map(post => (
            <PostCard key={post.id} post={post} />
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
