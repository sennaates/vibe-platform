"use client"

import { useEffect, useState } from "react"
import Image from "next/image"
import Link from "next/link"
import { Plus } from "lucide-react"
import { collection, query, where, orderBy, getDocs } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { profileColors } from "@/lib/design"
import { formatRelativeTime } from "@/lib/utils"
import type { Post } from "@/types"

export default function GalleryPage() {
  const { user, loading } = useAuth()
  const [posts, setPosts]       = useState<Post[]>([])
  const [fetching, setFetching] = useState(true)

  useEffect(() => {
    if (!user) { setFetching(false); return }
    const q = query(
      collection(db, "posts"),
      where("userId", "==", user.uid),
      orderBy("createdAt", "desc")
    )
    getDocs(q).then(snap => {
      setPosts(snap.docs.map(d => ({ id: d.id, ...d.data() } as Post)))
      setFetching(false)
    })
  }, [user])

  if (loading || fetching) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="flex items-center justify-between mb-6 animate-pulse">
          <div>
            <div className="h-6 w-24 bg-[#E8E4DC] rounded-full mb-2" />
            <div className="h-3.5 w-16 bg-[#E8E4DC] rounded-full" />
          </div>
          <div className="h-9 w-28 bg-[#E8E4DC] rounded-[12px]" />
        </div>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-2 animate-pulse">
          {[...Array(12)].map((_, i) => (
            <div key={i} className="aspect-square bg-[#E8E4DC] rounded-[14px]" />
          ))}
        </div>
      </div>
    )
  }

  if (!user) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[calc(100vh-56px)] gap-4 px-4">
        <span className="text-6xl block">🖼️</span>
        <p className="text-xl font-bold text-[#1C1917]">Galeriyi görmek için giriş yap</p>
        <p className="text-sm text-[#78716C]">Çizimlerini burada sakla ve paylaş</p>
        <Link
          href="/auth"
          className="mt-3 px-6 py-3 bg-[#D9723F] text-white rounded-[14px] text-sm font-semibold shadow-sm hover:bg-[#C4622F] transition-colors"
        >
          Giriş Yap
        </Link>
      </div>
    )
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-6 sm:mb-8">
        <div>
          <p className="text-xs font-semibold text-[#A8A29E] uppercase tracking-widest mb-0.5">Koleksiyon</p>
          <h1 className="text-2xl sm:text-3xl font-bold text-[#1C1917]">Galeri</h1>
          <p className="text-sm text-[#78716C] mt-0.5">{posts.length} çizim</p>
        </div>
        <Link
          href="/canvas"
          className="flex items-center gap-1.5 px-5 py-2.5 bg-[#D9723F] text-white rounded-[14px] text-sm font-semibold shadow-sm hover:bg-[#C4622F] transition-all active:scale-95"
        >
          <Plus size={16} strokeWidth={2.5} />
          Yeni Çizim
        </Link>
      </div>

      {posts.length === 0 ? (
        <div className="flex flex-col items-center py-24 text-center gap-3">
          <span className="text-6xl block">🎨</span>
          <p className="font-bold text-[#1C1917] text-xl">Henüz çizim yok</p>
          <p className="text-sm text-[#78716C]">İlk çizimini yap ve galerine ekle</p>
          <Link
            href="/canvas"
            className="mt-4 px-6 py-3 bg-[#D9723F] text-white rounded-[14px] text-sm font-semibold shadow-sm hover:bg-[#C4622F] transition-colors"
          >
            Çizmeye Başla
          </Link>
        </div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-2 sm:gap-3">
          {posts.map(post => {
            const accent = profileColors[post.userColor] ?? "#4A7FA5"
            return (
              <Link
                key={post.id}
                href={`/post/${post.id}`}
                className="aspect-square relative rounded-[14px] overflow-hidden bg-[#F5F3EF] group shadow-sm hover:shadow-md transition-shadow"
              >
                {post.imageUrl ? (
                  <Image
                    src={post.imageUrl}
                    alt={post.emotion}
                    fill
                    className="object-cover group-hover:scale-105 transition-transform duration-300"
                    sizes="(max-width: 640px) 50vw, (max-width: 1024px) 25vw, 16vw"
                  />
                ) : (
                  <div
                    className="w-full h-full flex items-center justify-center text-3xl"
                    style={{ background: `linear-gradient(135deg, ${accent}30, transparent)` }}
                  >
                    🎨
                  </div>
                )}
                <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-200 flex items-end p-3">
                  <div>
                    <p className="text-white text-xs font-semibold leading-tight">{post.emotion}</p>
                    <p className="text-white/70 text-[10px] mt-0.5">{formatRelativeTime(post.createdAt)}</p>
                  </div>
                </div>
              </Link>
            )
          })}
        </div>
      )}
    </div>
  )
}
