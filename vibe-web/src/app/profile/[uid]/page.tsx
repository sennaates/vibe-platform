"use client"

import { use, useEffect, useState } from "react"
import Image from "next/image"
import Link from "next/link"
import {
  doc, getDoc, collection, query, where, orderBy, getDocs,
  setDoc, deleteDoc, updateDoc, increment, serverTimestamp
} from "firebase/firestore"
import { Grid3X3, Heart } from "lucide-react"
import { useRouter } from "next/navigation"
import { ArrowLeft, Settings, UserPlus, UserCheck, Loader2 } from "lucide-react"
import { db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { profileColors } from "@/lib/design"
import { createNotification } from "@/lib/notifications"
import { FollowListModal } from "@/components/profile/FollowListModal"
import type { SocialUser, Post } from "@/types"

export default function ProfilePage({ params }: { params: Promise<{ uid: string }> }) {
  const { uid } = use(params)
  const { user, profile: myProfile } = useAuth()
  const router = useRouter()

  const [pageProfile, setPageProfile]       = useState<SocialUser | null>(null)
  const [posts, setPosts]                   = useState<Post[]>([])
  const [loading, setLoading]               = useState(true)
  const [following, setFollowing]           = useState(false)
  const [followLoading, setFollowLoading]   = useState(false)
  const [localFollowers, setLocalFollowers] = useState(0)
  const [followModal, setFollowModal]       = useState<"followers" | "following" | null>(null)
  const [profileTab, setProfileTab]         = useState<"posts" | "liked">("posts")
  const [likedPosts, setLikedPosts]         = useState<Post[]>([])
  const [likedLoading, setLikedLoading]     = useState(false)

  const isOwn  = user?.uid === uid
  const accent = profileColors[pageProfile?.profileColor ?? "blue"] ?? "#4A7FA5"

  useEffect(() => {
    async function load() {
      const snap = await getDoc(doc(db, "users", uid))
      if (!snap.exists()) { setLoading(false); return }
      const data = snap.data() as SocialUser
      setPageProfile(data)
      setLocalFollowers(data.followersCount)
      const q = query(collection(db, "posts"), where("userId", "==", uid), orderBy("createdAt", "desc"))
      const postSnap = await getDocs(q)
      setPosts(postSnap.docs.map(d => ({ id: d.id, ...d.data() } as Post)))
      setLoading(false)
    }
    load()
  }, [uid])

  useEffect(() => {
    if (!user || isOwn) return
    getDoc(doc(db, "follows", `${user.uid}_${uid}`)).then(snap => setFollowing(snap.exists()))
  }, [user, uid, isOwn])

  // Load liked posts on tab switch
  useEffect(() => {
    if (profileTab !== "liked" || likedPosts.length > 0) return
    setLikedLoading(true)
    async function loadLiked() {
      const snap = await getDocs(
        query(collection(db, "userLikes", uid, "items"), orderBy("likedAt", "desc"))
      )
      const postIds = snap.docs.map(d => d.data().postId as string)
      if (postIds.length === 0) { setLikedLoading(false); return }
      const postDocs = await Promise.all(postIds.map(pid => getDoc(doc(db, "posts", pid))))
      setLikedPosts(postDocs.filter(d => d.exists()).map(d => ({ id: d.id, ...d.data() } as Post)))
      setLikedLoading(false)
    }
    loadLiked()
  }, [profileTab, uid, likedPosts.length])

  async function handleFollow() {
    if (!user) { router.push("/auth"); return }
    setFollowLoading(true)
    const followRef = doc(db, "follows", `${user.uid}_${uid}`)
    if (following) {
      await deleteDoc(followRef)
      await updateDoc(doc(db, "users", uid), { followersCount: increment(-1) })
      await updateDoc(doc(db, "users", user.uid), { followingCount: increment(-1) })
      setFollowing(false)
      setLocalFollowers(c => c - 1)
    } else {
      await setDoc(followRef, { followerId: user.uid, followedId: uid, createdAt: serverTimestamp() })
      await updateDoc(doc(db, "users", uid), { followersCount: increment(1) })
      await updateDoc(doc(db, "users", user.uid), { followingCount: increment(1) })
      if (myProfile) {
        await createNotification({
          targetUserId:   uid,
          type:           "follow",
          fromUserId:     user.uid,
          fromUserName:   myProfile.displayName,
          fromUserAvatar: myProfile.avatarEmoji,
          fromUserColor:  myProfile.profileColor,
        })
      }
      setFollowing(true)
      setLocalFollowers(c => c + 1)
    }
    setFollowLoading(false)
  }


  if (loading) {
    return (
      <div className="animate-pulse">
        <div className="h-40 sm:h-52 bg-rim" />
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 -mt-12">
          <div className="w-24 h-24 rounded-full bg-rim border-4 border-[#FAF8F4]" />
          <div className="mt-4 space-y-2">
            <div className="h-6 w-40 bg-rim rounded-full" />
            <div className="h-4 w-24 bg-rim rounded-full" />
          </div>
        </div>
      </div>
    )
  }

  if (!pageProfile) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[calc(100vh-56px)] gap-4">
        <span className="text-5xl block">👤</span>
        <p className="text-ink-muted font-medium text-lg">Kullanıcı bulunamadı</p>
        <Link href="/" className="text-accent text-sm font-semibold hover:underline">Ana sayfaya dön</Link>
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
        {!isOwn && (
          <Link
            href="/"
            className="absolute top-4 left-4 sm:left-6 flex items-center gap-1.5 text-sm font-medium text-white/80 bg-black/15 hover:bg-black/25 backdrop-blur-sm px-3 py-1.5 rounded-full transition-colors"
          >
            <ArrowLeft size={14} />
            Geri
          </Link>
        )}
        {isOwn && (
          <Link
            href="/settings"
            className="absolute top-4 right-4 sm:right-6 flex items-center gap-1.5 text-xs font-semibold text-white/80 bg-black/15 hover:bg-black/25 backdrop-blur-sm px-3 py-1.5 rounded-full transition-colors"
          >
            <Settings size={12} />
            Ayarlar
          </Link>
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
            {pageProfile.avatarEmoji}
          </div>

          <div className="flex gap-2 mb-1">
            {isOwn ? (
              <>
                <Link href="/profile/edit"
                  className="px-4 py-2 bg-surface border border-rim text-ink rounded-[14px] text-sm font-semibold shadow-sm hover:bg-surface-muted transition-colors">
                  Düzenle
                </Link>
                <Link href="/canvas"
                  className="px-4 py-2 bg-accent text-white rounded-[14px] text-sm font-semibold shadow-sm hover:bg-accent-hover transition-colors">
                  + Çizim
                </Link>
              </>
            ) : (
              <button
                onClick={handleFollow}
                disabled={followLoading}
                className="flex items-center gap-1.5 px-5 py-2 rounded-[14px] text-sm font-semibold shadow-sm transition-all active:scale-95 disabled:opacity-60"
                style={following
                  ? { backgroundColor: "#F5F3EF", color: "#78716C", border: "1px solid #E8E4DC" }
                  : { backgroundColor: accent, color: "#fff" }
                }
              >
                {followLoading
                  ? <Loader2 size={14} className="animate-spin" />
                  : following
                    ? <><UserCheck size={14} /> Takip Ediliyor</>
                    : <><UserPlus size={14} /> Takip Et</>
                }
              </button>
            )}
          </div>
        </div>

        <h1 className="font-bold text-ink text-2xl sm:text-3xl">{pageProfile.displayName}</h1>
        {pageProfile.bio && (
          <p className="text-sm sm:text-base text-ink-muted mt-1.5 max-w-lg leading-relaxed">{pageProfile.bio}</p>
        )}

        {/* Stats */}
        <div className="flex gap-6 sm:gap-8 mt-5 pb-6 border-b border-rim">
          <StatPill value={pageProfile.postsCount} label="çizim" />
          <StatPill value={localFollowers} label="takipçi" onClick={() => setFollowModal("followers")} />
          <StatPill value={pageProfile.followingCount} label="takip" onClick={() => setFollowModal("following")} />
        </div>

        {/* Follow list modal */}
        {followModal && (
          <FollowListModal uid={uid} mode={followModal} onClose={() => setFollowModal(null)} />
        )}

        {/* Tab bar */}
        <div className="flex border-b border-rim mt-2">
          <ProfileTabBtn active={profileTab === "posts"} onClick={() => setProfileTab("posts")}>
            <Grid3X3 size={15} /> Çizimler
          </ProfileTabBtn>
          <ProfileTabBtn active={profileTab === "liked"} onClick={() => setProfileTab("liked")}>
            <Heart size={15} /> Beğendikleri
          </ProfileTabBtn>
        </div>

        {/* Grid */}
        <div className="py-5 sm:py-6">
          {profileTab === "posts" ? (
            posts.length === 0 ? (
              <div className="flex flex-col items-center py-20 text-center gap-3">
                <span className="text-5xl block">🎨</span>
                <p className="text-sm font-medium text-ink-muted">
                  {isOwn ? "Henüz çizim paylaşmadın" : "Henüz çizim yok"}
                </p>
                {isOwn && (
                  <Link href="/canvas" className="mt-2 px-5 py-2.5 bg-accent text-white rounded-[14px] text-sm font-semibold shadow-sm">
                    İlk çizimi yap
                  </Link>
                )}
              </div>
            ) : (
              <PostGrid posts={posts} />
            )
          ) : (
            likedLoading ? (
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-2 sm:gap-3 animate-pulse">
                {[...Array(6)].map((_, i) => <div key={i} className="aspect-square bg-rim rounded-[14px]" />)}
              </div>
            ) : likedPosts.length === 0 ? (
              <div className="flex flex-col items-center py-20 text-center gap-3">
                <span className="text-5xl block">❤️</span>
                <p className="text-sm font-medium text-ink-muted">
                  {isOwn ? "Henüz beğendiğin çizim yok" : "Henüz beğeni yok"}
                </p>
              </div>
            ) : (
              <PostGrid posts={likedPosts} />
            )
          )}
        </div>
      </div>
    </div>
  )
}

function PostGrid({ posts }: { posts: Post[] }) {
  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-2.5 sm:gap-3">
      {posts.map(post => {
        const postAccent = profileColors[post.userColor] ?? "#4A7FA5"
        return (
          <Link
            key={post.id}
            href={`/post/${post.id}`}
            className="aspect-square relative rounded-[14px] overflow-hidden bg-surface-muted group shadow-sm hover:shadow-md transition-shadow"
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
  )
}

function ProfileTabBtn({ active, onClick, children }: {
  active: boolean; onClick: () => void; children: React.ReactNode
}) {
  return (
    <button
      onClick={onClick}
      className={`flex items-center gap-1.5 px-5 py-3 text-sm font-semibold border-b-2 transition-colors ${
        active
          ? "border-[#1C1917] text-ink"
          : "border-transparent text-ink-subtle hover:text-ink-muted"
      }`}
    >
      {children}
    </button>
  )
}

function StatPill({ value, label, onClick }: { value: number; label: string; onClick?: () => void }) {
  if (onClick) {
    return (
      <button
        onClick={onClick}
        className="text-left hover:opacity-70 transition-opacity active:scale-95"
      >
        <span className="font-bold text-ink text-xl sm:text-2xl">{value}</span>
        <span className="text-sm text-ink-muted ml-1.5 underline-offset-2 hover:underline">{label}</span>
      </button>
    )
  }
  return (
    <div>
      <span className="font-bold text-ink text-xl sm:text-2xl">{value}</span>
      <span className="text-sm text-ink-muted ml-1.5">{label}</span>
    </div>
  )
}
