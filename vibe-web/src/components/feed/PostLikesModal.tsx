"use client"

import { useEffect, useState } from "react"
import { collection, query, orderBy, onSnapshot } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { X } from "lucide-react"
import Link from "next/link"
import { Avatar } from "@/components/ui/Avatar"

interface PostLikesModalProps {
  postId: string
  onClose: () => void
}

interface LikeItem {
  userId: string
  userName?: string
  userAvatar?: string
  userColor?: string
  createdAt: unknown
}

export function PostLikesModal({ postId, onClose }: PostLikesModalProps) {
  const [likes, setLikes] = useState<LikeItem[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const q = query(
      collection(db, "posts", postId, "likes"),
      orderBy("createdAt", "desc")
    )
    const unsub = onSnapshot(q, (snap) => {
      const items = snap.docs.map(doc => ({
        userId: doc.id,
        ...doc.data()
      })) as LikeItem[]
      setLikes(items)
      setLoading(false)
    })
    return () => unsub()
  }, [postId])

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
      {/* Backdrop (Tıklayınca Kapat) */}
      <div className="absolute inset-0" onClick={onClose} />
      
      <div className="relative w-full max-w-sm bg-surface rounded-[24px] shadow-xl overflow-hidden flex flex-col max-h-[80vh]">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-rim">
          <h2 className="text-lg font-semibold text-ink">Beğenenler</h2>
          <button
            onClick={onClose}
            className="p-2 -mr-2 rounded-full text-ink-subtle hover:bg-surface-muted transition-colors"
          >
            <X size={20} />
          </button>
        </div>

        {/* List */}
        <div className="flex-1 overflow-y-auto p-2">
          {loading ? (
            <div className="flex justify-center py-10">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent"></div>
            </div>
          ) : likes.length === 0 ? (
            <div className="text-center py-10 text-ink-muted">
              Henüz kimse beğenmemiş.
            </div>
          ) : (
            <div className="flex flex-col">
              {likes.map((like) => {
                const displayName = like.userName || "Kullanıcı"
                const avatar = like.userAvatar || "👤"
                const color = like.userColor || "blue"
                
                return (
                  <Link
                    key={like.userId}
                    href={`/profile/${like.userId}`}
                    onClick={onClose}
                    className="flex items-center gap-3 p-3 rounded-[16px] hover:bg-surface-muted transition-colors"
                  >
                    <Avatar emoji={avatar} color={color} size="md" />
                    <span className="font-medium text-ink text-sm">
                      {displayName}
                    </span>
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
