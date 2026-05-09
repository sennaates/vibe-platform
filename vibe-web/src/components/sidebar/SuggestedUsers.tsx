"use client"

import { useEffect, useState } from "react"
import Link from "next/link"
import {
  collection, query, limit, getDocs, where,
  doc, setDoc, deleteDoc, updateDoc, increment, serverTimestamp
} from "firebase/firestore"
import { UserPlus, UserCheck, Loader2, Users } from "lucide-react"
import { db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { Avatar } from "@/components/ui/Avatar"
import { profileColors } from "@/lib/design"
import { createNotification } from "@/lib/notifications"
import type { SocialUser } from "@/types"

interface Suggestion extends SocialUser {
  isFollowing: boolean
  followLoading: boolean
}

export function SuggestedUsers() {
  const { user, profile } = useAuth()
  const [suggestions, setSuggestions] = useState<Suggestion[]>([])

  useEffect(() => {
    if (!user) return
    async function load() {
      // Fetch users I already follow
      const followSnap = await getDocs(
        query(collection(db, "follows"), where("followerId", "==", user!.uid), limit(100))
      )
      const followingIds = new Set(followSnap.docs.map(d => d.data().followedId as string))
      followingIds.add(user!.uid) // exclude self

      // Get recent users
      const usersSnap = await getDocs(query(collection(db, "users"), limit(20)))
      const candidates = usersSnap.docs
        .map(d => d.data() as SocialUser)
        .filter(u => !followingIds.has(u.uid))
        .sort(() => Math.random() - 0.5)
        .slice(0, 3)

      setSuggestions(candidates.map(u => ({ ...u, isFollowing: false, followLoading: false })))
    }
    load()
  }, [user])

  if (!user || suggestions.length === 0) return null

  async function toggleFollow(targetUid: string) {
    if (!user || !profile) return
    setSuggestions(prev => prev.map(s => s.uid === targetUid ? { ...s, followLoading: true } : s))
    const target = suggestions.find(s => s.uid === targetUid)!
    const followRef = doc(db, "follows", `${user.uid}_${targetUid}`)

    if (target.isFollowing) {
      await deleteDoc(followRef)
      await updateDoc(doc(db, "users", targetUid), { followersCount: increment(-1) })
      await updateDoc(doc(db, "users", user.uid), { followingCount: increment(-1) })
      setSuggestions(prev => prev.map(s => s.uid === targetUid
        ? { ...s, isFollowing: false, followLoading: false }
        : s
      ))
    } else {
      await setDoc(followRef, { followerId: user.uid, followedId: targetUid, createdAt: serverTimestamp() })
      await updateDoc(doc(db, "users", targetUid), { followersCount: increment(1) })
      await updateDoc(doc(db, "users", user.uid), { followingCount: increment(1) })
      await createNotification({
        targetUserId: targetUid, type: "follow",
        fromUserId: user.uid, fromUserName: profile.displayName,
        fromUserAvatar: profile.avatarEmoji, fromUserColor: profile.profileColor,
      })
      setSuggestions(prev => prev.map(s => s.uid === targetUid
        ? { ...s, isFollowing: true, followLoading: false }
        : s
      ))
    }
  }

  return (
    <div className="bg-white border border-[#E8E4DC] rounded-[22px] p-5 shadow-sm">
      <div className="flex items-center gap-2 mb-4">
        <Users size={15} className="text-[#D9723F]" />
        <p className="text-xs font-semibold text-[#A8A29E] uppercase tracking-widest">Tanıyor Olabilirsin</p>
      </div>
      <div className="space-y-3">
        {suggestions.map(u => {
          const accent = profileColors[u.profileColor] ?? "#4A7FA5"
          return (
            <div key={u.uid} className="flex items-center gap-2.5">
              <Link href={`/profile/${u.uid}`} className="shrink-0">
                <Avatar emoji={u.avatarEmoji} color={u.profileColor} size="sm" />
              </Link>
              <div className="flex-1 min-w-0">
                <Link href={`/profile/${u.uid}`} className="text-xs font-semibold text-[#1C1917] hover:underline truncate block">
                  {u.displayName}
                </Link>
                <p className="text-[10px] text-[#A8A29E]">{u.postsCount} çizim</p>
              </div>
              <button
                onClick={() => toggleFollow(u.uid)}
                disabled={u.followLoading}
                className="flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-semibold shrink-0 transition-all disabled:opacity-60"
                style={u.isFollowing
                  ? { backgroundColor: "#F5F3EF", color: "#78716C", border: "1px solid #E8E4DC" }
                  : { backgroundColor: accent + "18", color: accent, border: `1px solid ${accent}30` }
                }
              >
                {u.followLoading
                  ? <Loader2 size={10} className="animate-spin" />
                  : u.isFollowing
                    ? <><UserCheck size={10} />Takipte</>
                    : <><UserPlus size={10} />Takip</>
                }
              </button>
            </div>
          )
        })}
      </div>
      <Link href="/search" className="block mt-4 text-center text-xs text-[#D9723F] hover:underline font-medium">
        Daha fazla kullanıcı bul →
      </Link>
    </div>
  )
}
