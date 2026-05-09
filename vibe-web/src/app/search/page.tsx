"use client"

import { useState, useTransition } from "react"
import Link from "next/link"
import { collection, query, where, getDocs, limit, doc, getDoc, setDoc, deleteDoc, updateDoc, increment, serverTimestamp } from "firebase/firestore"
import { Search, Loader2, UserPlus, UserCheck } from "lucide-react"
import { db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { useRouter } from "next/navigation"
import { Avatar } from "@/components/ui/Avatar"
import { profileColors } from "@/lib/design"
import { createNotification } from "@/lib/notifications"
import type { SocialUser } from "@/types"

interface Result extends SocialUser {
  isFollowing: boolean
  followLoading: boolean
}

export default function SearchPage() {
  const { user, profile } = useAuth()
  const router = useRouter()
  const [term, setTerm]       = useState("")
  const [results, setResults] = useState<Result[]>([])
  const [searched, setSearched] = useState(false)
  const [isPending, startTransition] = useTransition()

  async function doSearch(value: string) {
    const trimmed = value.trim()
    if (!trimmed) { setResults([]); setSearched(false); return }

    // If starts with #, navigate to hashtag page
    if (trimmed.startsWith("#") && trimmed.length > 1) {
      router.push(`/hashtag/${trimmed.slice(1).toLowerCase()}`)
      return
    }

    startTransition(async () => {
      const q = query(
        collection(db, "users"),
        where("displayName", ">=", value),
        where("displayName", "<=", value + ""),
        limit(15)
      )
      const snap = await getDocs(q)
      const users = snap.docs
        .map(d => d.data() as SocialUser)
        .filter(u => u.uid !== user?.uid) // exclude self

      // check follow status for each
      let followSet = new Set<string>()
      if (user) {
        await Promise.all(users.map(async u => {
          const fsnap = await getDoc(doc(db, "follows", `${user.uid}_${u.uid}`))
          if (fsnap.exists()) followSet.add(u.uid)
        }))
      }

      setResults(users.map(u => ({ ...u, isFollowing: followSet.has(u.uid), followLoading: false })))
      setSearched(true)
    })
  }

  async function toggleFollow(targetUid: string) {
    if (!user || !profile) { router.push("/auth"); return }

    setResults(prev => prev.map(r => r.uid === targetUid ? { ...r, followLoading: true } : r))
    const target = results.find(r => r.uid === targetUid)!
    const followRef = doc(db, "follows", `${user.uid}_${targetUid}`)

    if (target.isFollowing) {
      await deleteDoc(followRef)
      await updateDoc(doc(db, "users", targetUid), { followersCount: increment(-1) })
      await updateDoc(doc(db, "users", user.uid), { followingCount: increment(-1) })
      setResults(prev => prev.map(r => r.uid === targetUid
        ? { ...r, isFollowing: false, followLoading: false, followersCount: r.followersCount - 1 }
        : r
      ))
    } else {
      await setDoc(followRef, { followerId: user.uid, followedId: targetUid, createdAt: serverTimestamp() })
      await updateDoc(doc(db, "users", targetUid), { followersCount: increment(1) })
      await updateDoc(doc(db, "users", user.uid), { followingCount: increment(1) })
      await createNotification({
        targetUserId:   targetUid,
        type:           "follow",
        fromUserId:     user.uid,
        fromUserName:   profile.displayName,
        fromUserAvatar: profile.avatarEmoji,
        fromUserColor:  profile.profileColor,
      })
      setResults(prev => prev.map(r => r.uid === targetUid
        ? { ...r, isFollowing: true, followLoading: false, followersCount: r.followersCount + 1 }
        : r
      ))
    }
  }

  return (
    <div className="max-w-2xl mx-auto px-4 py-6 sm:py-10">
      <h1 className="text-2xl font-bold text-ink mb-6">Kullanıcı Ara</h1>

      {/* Search input */}
      <div className="relative mb-6">
        <Search size={17} className="absolute left-4 top-1/2 -translate-y-1/2 text-ink-subtle" />
        <input
          type="text"
          value={term}
          onChange={e => { setTerm(e.target.value); doSearch(e.target.value) }}
          placeholder="İsim veya #hashtag ara…"
          className="w-full pl-11 pr-4 py-3 rounded-[16px] bg-surface border border-rim text-sm text-ink placeholder:text-ink-subtle focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent shadow-sm transition"
        />
        {isPending && (
          <Loader2 size={16} className="absolute right-4 top-1/2 -translate-y-1/2 text-ink-subtle animate-spin" />
        )}
      </div>

      {/* Results */}
      {results.length > 0 ? (
        <div className="bg-surface border border-rim rounded-[22px] shadow-sm divide-y divide-surface-muted overflow-hidden">
          {results.map(u => {
            const accent = profileColors[u.profileColor] ?? "#4A7FA5"
            return (
              <div key={u.uid} className="flex items-center gap-3 px-4 sm:px-5 py-3 sm:py-4">
                <Link href={`/profile/${u.uid}`} className="shrink-0">
                  <Avatar emoji={u.avatarEmoji} color={u.profileColor} size="md" />
                </Link>
                <div className="flex-1 min-w-0">
                  <Link href={`/profile/${u.uid}`} className="font-semibold text-ink text-sm hover:underline block truncate">
                    {u.displayName}
                  </Link>
                  <p className="text-xs text-ink-subtle mt-0.5">
                    {u.postsCount} çizim · {u.followersCount} takipçi
                  </p>
                </div>
                {user && (
                  <button
                    onClick={() => toggleFollow(u.uid)}
                    disabled={u.followLoading}
                    className="flex items-center gap-1.5 px-4 py-2 min-h-[40px] rounded-full text-xs font-semibold shrink-0 transition-all active:scale-95 disabled:opacity-60"
                    style={u.isFollowing
                      ? { backgroundColor: "#F5F3EF", color: "#78716C", border: "1px solid #E8E4DC" }
                      : { backgroundColor: accent, color: "#fff" }
                    }
                  >
                    {u.followLoading
                      ? <Loader2 size={12} className="animate-spin" />
                      : u.isFollowing
                        ? <><UserCheck size={13} />Takipte</>
                        : <><UserPlus size={13} />Takip</>
                    }
                  </button>
                )}
              </div>
            )
          })}
        </div>
      ) : searched && !isPending ? (
        <div className="flex flex-col items-center py-20 text-center gap-3">
          <span className="text-5xl">🔍</span>
          <p className="text-sm font-medium text-ink-muted">&ldquo;{term}&rdquo; için sonuç bulunamadı</p>
          <p className="text-xs text-ink-subtle">Büyük/küçük harf farkına dikkat et</p>
        </div>
      ) : !term ? (
        <div className="flex flex-col items-center py-24 text-center gap-3">
          <span className="text-5xl">👥</span>
          <p className="text-sm text-ink-muted">Takip etmek istediğin kişileri bul</p>
        </div>
      ) : null}
    </div>
  )
}
