"use client"

import { useEffect, useState } from "react"
import Link from "next/link"
import {
  collection, query, where, getDocs, orderBy, limit, doc, getDoc, Timestamp
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

export function FollowingFeed() {
  const { user } = useAuth()
  const [posts, setPosts]     = useState<Post[]>([])
  const [liked, setLiked]     = useState<Set<string>>(new Set())
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!user) { setLoading(false); return }
    const currentUid = user.uid

    async function load() {
      // Get list of followed user IDs
      const followSnap = await getDocs(
        query(collection(db, "follows"), where("followerId", "==", currentUid), limit(30))
      )
      const followedIds = followSnap.docs.map(d => d.data().followedId as string)

      if (followedIds.length === 0) { setLoading(false); return }

      // Fetch posts from followed users (Firestore "in" supports up to 30)
      const postsSnap = await getDocs(
        query(
          collection(db, "posts"),
          where("userId", "in", followedIds),
          orderBy("createdAt", "desc"),
          limit(40)
        )
      )
      const fetched = postsSnap.docs.map(d => ({ id: d.id, ...d.data() } as Post))
      setPosts(fetched)

      // Check liked status
      const likedSet = new Set<string>()
      await Promise.all(
        fetched.map(async p => {
          const snap = await getDoc(doc(db, "posts", p.id, "likes", currentUid))
          if (snap.exists()) likedSet.add(p.id)
        })
      )
      setLiked(likedSet)
      setLoading(false)
    }

    load()
  }, [user])

  if (loading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
        {[...Array(3)].map((_, i) => <PostSkeleton key={i} />)}
      </div>
    )
  }

  if (!user) {
    return (
      <div className="flex flex-col items-center py-24 text-center gap-3">
        <span className="text-5xl">🔒</span>
        <p className="text-[#1C1917] font-semibold">Takip feed'ini görmek için giriş yap</p>
        <Link href="/auth" className="mt-1 px-5 py-2.5 bg-[#D9723F] text-white rounded-[14px] text-sm font-semibold">
          Giriş Yap
        </Link>
      </div>
    )
  }

  if (posts.length === 0) {
    return (
      <div className="flex flex-col items-center py-24 text-center gap-3">
        <span className="text-5xl">👥</span>
        <p className="text-[#1C1917] font-semibold text-lg">Henüz takip ettiğin biri yok</p>
        <p className="text-sm text-[#78716C] max-w-xs">
          Birini takip ettiğinde çizimleri burada belirecek
        </p>
        <Link
          href="/search"
          className="mt-2 px-5 py-2.5 bg-[#D9723F] text-white rounded-[14px] text-sm font-semibold shadow-sm hover:bg-[#C4622F] transition-colors"
        >
          Kullanıcı Ara
        </Link>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
      {posts.map(post => (
        <PostCard key={post.id} post={post} isLiked={liked.has(post.id)} />
      ))}
    </div>
  )
}
