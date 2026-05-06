"use client"

import { useEffect, useState } from "react"
import {
  collection, query, orderBy, limit,
  onSnapshot, doc, getDoc
} from "firebase/firestore"
import { db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { PostCard } from "./PostCard"
import type { Post } from "@/types"

function PostSkeleton() {
  return (
    <div className="bg-white border border-[#E8E4DC] rounded-[18px] overflow-hidden shadow-sm animate-pulse">
      <div className="flex items-center gap-3 px-5 pt-5 pb-3">
        <div className="w-9 h-9 rounded-full bg-[#E8E4DC] shrink-0" />
        <div className="flex-1">
          <div className="h-3 bg-[#E8E4DC] rounded-full w-28 mb-2" />
          <div className="h-2.5 bg-[#E8E4DC] rounded-full w-16" />
        </div>
        <div className="h-6 w-20 bg-[#E8E4DC] rounded-full" />
      </div>
      <div className="aspect-square bg-[#F5F3EF]" />
      <div className="flex items-center gap-5 px-5 py-3">
        <div className="h-5 w-12 bg-[#E8E4DC] rounded-full" />
        <div className="h-5 w-12 bg-[#E8E4DC] rounded-full" />
      </div>
    </div>
  )
}

export function Feed() {
  const { user } = useAuth()
  const [posts, setPosts]     = useState<Post[]>([])
  const [liked, setLiked]     = useState<Set<string>>(new Set())
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const q = query(
      collection(db, "posts"),
      orderBy("createdAt", "desc"),
      limit(30)
    )

    const unsub = onSnapshot(q, async (snap) => {
      const fetched = snap.docs.map(d => ({ id: d.id, ...d.data() } as Post))
      setPosts(fetched)

      if (user) {
        const likedSet = new Set<string>()
        await Promise.all(
          fetched.map(async (p) => {
            const likeSnap = await getDoc(doc(db, "posts", p.id, "likes", user.uid))
            if (likeSnap.exists()) likedSet.add(p.id)
          })
        )
        setLiked(likedSet)
      }

      setLoading(false)
    })

    return unsub
  }, [user])

  if (loading) {
    return (
      <section>
        <div className="flex items-center gap-3 mb-6">
          <div className="flex-1 h-px bg-[#E8E4DC]" />
          <span className="text-xs font-semibold text-[#A8A29E] uppercase tracking-widest">Akış</span>
          <div className="flex-1 h-px bg-[#E8E4DC]" />
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
          {[...Array(6)].map((_, i) => <PostSkeleton key={i} />)}
        </div>
      </section>
    )
  }

  if (posts.length === 0) {
    return (
      <section>
        <div className="flex items-center gap-3 mb-6">
          <div className="flex-1 h-px bg-[#E8E4DC]" />
          <span className="text-xs font-semibold text-[#A8A29E] uppercase tracking-widest">Akış</span>
          <div className="flex-1 h-px bg-[#E8E4DC]" />
        </div>
        <div className="flex flex-col items-center justify-center py-24 text-center">
          <span className="text-6xl mb-4 block">🎨</span>
          <p className="text-[#1C1917] font-semibold text-lg">Henüz paylaşım yok</p>
          <p className="text-[#78716C] text-sm mt-1.5">İlk çizimi paylaşan sen ol</p>
        </div>
      </section>
    )
  }

  return (
    <section>
      <div className="flex items-center gap-3 mb-6">
        <div className="flex-1 h-px bg-[#E8E4DC]" />
        <span className="text-xs font-semibold text-[#A8A29E] uppercase tracking-widest">Akış</span>
        <div className="flex-1 h-px bg-[#E8E4DC]" />
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
        {posts.map(post => (
          <PostCard key={post.id} post={post} isLiked={liked.has(post.id)} />
        ))}
      </div>
    </section>
  )
}
