"use client"

import { useEffect, useState } from "react"
import Link from "next/link"
import { collection, query, where, getDocs, doc, getDoc } from "firebase/firestore"
import { X, Loader2 } from "lucide-react"
import { db } from "@/lib/firebase"
import { Avatar } from "@/components/ui/Avatar"
import type { SocialUser } from "@/types"

interface FollowListModalProps {
  uid: string
  mode: "followers" | "following"
  onClose: () => void
}

export function FollowListModal({ uid, mode, onClose }: FollowListModalProps) {
  const [users, setUsers]   = useState<SocialUser[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function load() {
      // followers: docs where followedId == uid → get followerId
      // following: docs where followerId == uid → get followedId
      const field  = mode === "followers" ? "followedId" : "followerId"
      const target = mode === "followers" ? "followerId"  : "followedId"

      const snap = await getDocs(
        query(collection(db, "follows"), where(field, "==", uid))
      )
      const ids = snap.docs.map(d => d.data()[target] as string)

      const profiles = await Promise.all(
        ids.map(async id => {
          const s = await getDoc(doc(db, "users", id))
          return s.exists() ? (s.data() as SocialUser) : null
        })
      )
      setUsers(profiles.filter(Boolean) as SocialUser[])
      setLoading(false)
    }
    load()
  }, [uid, mode])

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
      <div className="bg-surface rounded-[22px] w-full max-w-sm shadow-xl overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-rim">
          <h2 className="font-bold text-ink">
            {mode === "followers" ? "Takipçiler" : "Takip Edilenler"}
          </h2>
          <button onClick={onClose} className="p-1.5 rounded-[8px] text-ink-subtle hover:bg-surface-muted">
            <X size={18} />
          </button>
        </div>

        {/* List */}
        <div className="max-h-[60vh] overflow-y-auto divide-y divide-surface-muted">
          {loading ? (
            <div className="flex items-center justify-center py-16">
              <Loader2 size={24} className="animate-spin text-ink-subtle" />
            </div>
          ) : users.length === 0 ? (
            <div className="flex flex-col items-center py-16 text-center gap-2">
              <span className="text-4xl">👥</span>
              <p className="text-sm text-ink-muted">
                {mode === "followers" ? "Henüz takipçi yok" : "Henüz kimse takip edilmiyor"}
              </p>
            </div>
          ) : (
            users.map(u => (
              <Link
                key={u.uid}
                href={`/profile/${u.uid}`}
                onClick={onClose}
                className="flex items-center gap-3 px-5 py-3.5 hover:bg-canvas transition-colors"
              >
                <Avatar emoji={u.avatarEmoji} color={u.profileColor} size="md" />
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-ink text-sm truncate">{u.displayName}</p>
                  <p className="text-xs text-ink-subtle mt-0.5">
                    {u.postsCount} çizim
                  </p>
                </div>
              </Link>
            ))
          )}
        </div>
      </div>
    </div>
  )
}
