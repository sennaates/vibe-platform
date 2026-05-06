"use client"

import { use, useEffect, useState } from "react"
import Image from "next/image"
import Link from "next/link"
import { doc, getDoc, collection, query, where, orderBy, getDocs } from "firebase/firestore"
import { signOut } from "firebase/auth"
import { useRouter } from "next/navigation"
import { ArrowLeft, LogOut } from "lucide-react"
import { auth, db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { profileColors } from "@/lib/design"
import type { SocialUser, Post } from "@/types"

export default function ProfilePage({ params }: { params: Promise<{ uid: string }> }) {
  const { uid } = use(params)
  const { user } = useAuth()
  const router = useRouter()

  const [profile, setProfile] = useState<SocialUser | null>(null)
  const [posts, setPosts]     = useState<Post[]>([])
  const [loading, setLoading] = useState(true)

  const isOwn  = user?.uid === uid
  const accent = profileColors[profile?.profileColor ?? "blue"] ?? "#4A7FA5"

  useEffect(() => {
    async function load() {
      const snap = await getDoc(doc(db, "users", uid))
      if (!snap.exists()) { setLoading(false); return }
      setProfile(snap.data() as SocialUser)
      const q = query(collection(db, "posts"), where("userId", "==", uid), orderBy("createdAt", "desc"))
      const postSnap = await getDocs(q)
      setPosts(postSnap.docs.map(d => ({ id: d.id, ...d.data() } as Post)))
      setLoading(false)
    }
    load()
  }, [uid])

  async function handleLogout() {
    await signOut(auth)
    router.push("/")
  }

  if (loading) {
    return (
      <div className="animate-pulse">
        <div className="h-40 sm:h-52 bg-[#E8E4DC]" />
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 -mt-12">
          <div className="w-24 h-24 rounded-full bg-[#E8E4DC] border-4 border-[#FAF8F4]" />
          <div className="mt-4 space-y-2">
            <div className="h-6 w-40 bg-[#E8E4DC] rounded-full" />
            <div className="h-4 w-24 bg-[#E8E4DC] rounded-full" />
          </div>
        </div>
      </div>
    )
  }

  if (!profile) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[calc(100vh-56px)] gap-4">
        <span className="text-5xl block">👤</span>
        <p className="text-[#78716C] font-medium text-lg">Kullanıcı bulunamadı</p>
        <Link href="/" className="text-[#D9723F] text-sm font-semibold hover:underline">Ana sayfaya dön</Link>
      </div>
    )
  }

  return (
    <div>
      {/* Full-width gradient banner */}
      <div
        className="w-full h-40 sm:h-52 lg:h-60 relative"
        style={{ background: `linear-gradient(135deg, ${accent}60, ${accent}25, ${accent}10)` }}
      >
        {/* Back button */}
        {!isOwn && (
          <Link
            href="/"
            className="absolute top-4 left-4 sm:left-6 flex items-center gap-1.5 text-sm font-medium text-white/80 bg-black/15 hover:bg-black/25 backdrop-blur-sm px-3 py-1.5 rounded-full transition-colors"
          >
            <ArrowLeft size={14} />
            Geri
          </Link>
        )}

        {/* Logout */}
        {isOwn && (
          <button
            onClick={handleLogout}
            className="absolute top-4 right-4 sm:right-6 flex items-center gap-1.5 text-xs font-semibold text-white/80 bg-black/15 hover:bg-black/25 backdrop-blur-sm px-3 py-1.5 rounded-full transition-colors"
          >
            <LogOut size={12} />
            Çıkış
          </button>
        )}
      </div>

      {/* Profile content */}
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Avatar overlapping banner */}
        <div className="-mt-14 sm:-mt-16 mb-4 flex items-end justify-between">
          <div
            className="w-24 h-24 sm:w-28 sm:h-28 rounded-full flex items-center justify-center text-5xl sm:text-6xl border-4 border-[#FAF8F4] shadow-md"
            style={{ backgroundColor: accent + "25" }}
          >
            {profile.avatarEmoji}
          </div>
          {isOwn && (
            <Link
              href="/canvas"
              className="px-4 py-2 bg-[#D9723F] text-white rounded-[14px] text-sm font-semibold shadow-sm hover:bg-[#C4622F] transition-colors mb-1"
            >
              + Yeni Çizim
            </Link>
          )}
        </div>

        <h1 className="font-bold text-[#1C1917] text-2xl sm:text-3xl">{profile.displayName}</h1>
        {profile.bio && <p className="text-sm sm:text-base text-[#78716C] mt-1.5 max-w-lg leading-relaxed">{profile.bio}</p>}

        {/* Stats */}
        <div className="flex gap-6 sm:gap-8 mt-5 pb-6 border-b border-[#E8E4DC]">
          <StatPill value={profile.postsCount} label="çizim" />
          <StatPill value={profile.followersCount} label="takipçi" />
          <StatPill value={profile.followingCount} label="takip" />
        </div>

        {/* Grid */}
        <div className="py-6 sm:py-8">
          {posts.length === 0 ? (
            <div className="flex flex-col items-center py-20 text-center gap-3">
              <span className="text-5xl block">🎨</span>
              <p className="text-sm font-medium text-[#78716C]">
                {isOwn ? "Henüz çizim paylaşmadın" : "Henüz çizim yok"}
              </p>
              {isOwn && (
                <Link href="/canvas" className="mt-2 px-5 py-2.5 bg-[#D9723F] text-white rounded-[14px] text-sm font-semibold shadow-sm">
                  İlk çizimi yap
                </Link>
              )}
            </div>
          ) : (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-2 sm:gap-3">
              {posts.map(post => {
                const postAccent = profileColors[post.userColor] ?? "#4A7FA5"
                return (
                  <Link
                    key={post.id}
                    href={`/post/${post.id}`}
                    className="aspect-square relative rounded-[14px] overflow-hidden bg-[#F5F3EF] group shadow-sm hover:shadow-md transition-shadow"
                  >
                    {post.imageUrl ? (
                      <Image
                        src={post.imageUrl} alt={post.emotion} fill
                        className="object-cover group-hover:scale-105 transition-transform duration-300"
                        sizes="(max-width: 640px) 50vw, (max-width: 1024px) 25vw, 20vw"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-3xl"
                        style={{ background: `linear-gradient(135deg, ${postAccent}30, transparent)` }}>
                        🎨
                      </div>
                    )}
                    <div className="absolute inset-0 bg-gradient-to-t from-black/40 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-200" />
                  </Link>
                )
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

function StatPill({ value, label }: { value: number; label: string }) {
  return (
    <div>
      <span className="font-bold text-[#1C1917] text-xl sm:text-2xl">{value}</span>
      <span className="text-sm text-[#78716C] ml-1.5">{label}</span>
    </div>
  )
}
