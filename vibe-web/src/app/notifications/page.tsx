"use client"

import { useEffect, useState } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import {
  collection, query, orderBy, limit,
  onSnapshot, writeBatch, doc, Timestamp
} from "firebase/firestore"
import { Heart, MessageCircle, UserPlus, Bell } from "lucide-react"
import { db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { Avatar } from "@/components/ui/Avatar"
import { formatRelativeTime } from "@/lib/utils"

interface Notif {
  id: string
  type: "follow" | "like" | "comment"
  fromUserId: string
  fromUserName: string
  fromUserAvatar: string
  fromUserColor: string
  postId?: string
  postImageUrl?: string
  read: boolean
  createdAt: Timestamp
}

const TYPE_META = {
  follow:  { icon: <UserPlus  size={14} />, color: "#6366f1", label: "seni takip etti" },
  like:    { icon: <Heart     size={14} />, color: "#e53e3e", label: "çizimini beğendi" },
  comment: { icon: <MessageCircle size={14} />, color: "#D9723F", label: "çizimine yorum yaptı" },
}

export default function NotificationsPage() {
  const { user, loading } = useAuth()
  const router = useRouter()
  const [notifs, setNotifs] = useState<Notif[]>([])
  const [fetching, setFetching] = useState(true)

  useEffect(() => {
    if (!loading && !user) router.push("/auth")
  }, [loading, user, router])

  useEffect(() => {
    if (!user) return
    const q = query(
      collection(db, "notifications", user.uid, "items"),
      orderBy("createdAt", "desc"),
      limit(50)
    )
    const unsub = onSnapshot(q, snap => {
      setNotifs(snap.docs.map(d => ({ id: d.id, ...d.data() } as Notif)))
      setFetching(false)
    })
    return unsub
  }, [user])

  // Mark all as read when page opens
  useEffect(() => {
    if (!user || notifs.length === 0) return
    const unread = notifs.filter(n => !n.read)
    if (unread.length === 0) return
    const batch = writeBatch(db)
    unread.forEach(n => batch.update(doc(db, "notifications", user.uid, "items", n.id), { read: true }))
    batch.commit()
  }, [user, notifs])

  if (loading || fetching) {
    return (
      <div className="max-w-2xl mx-auto px-4 py-8 space-y-3 animate-pulse">
        {[...Array(5)].map((_, i) => (
          <div key={i} className="bg-surface border border-rim rounded-[18px] p-4 flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-rim shrink-0" />
            <div className="flex-1 space-y-2">
              <div className="h-3 w-48 bg-rim rounded-full" />
              <div className="h-2.5 w-20 bg-rim rounded-full" />
            </div>
          </div>
        ))}
      </div>
    )
  }

  return (
    <div className="max-w-2xl mx-auto px-4 py-6 sm:py-10">
      <h1 className="text-2xl font-bold text-ink mb-6">Bildirimler</h1>

      {notifs.length === 0 ? (
        <div className="flex flex-col items-center py-24 text-center gap-3">
          <Bell size={48} className="text-[#E8E4DC]" />
          <p className="text-sm font-medium text-ink-muted">Henüz bildirim yok</p>
          <p className="text-xs text-ink-subtle">Biri seni takip ettiğinde veya çizimini beğendiğinde burada görünür</p>
        </div>
      ) : (
        <div className="bg-surface border border-rim rounded-[22px] shadow-sm divide-y divide-surface-muted overflow-hidden">
          {notifs.map(n => {
            const meta = TYPE_META[n.type]
            return (
              <div
                key={n.id}
                className={`flex items-center gap-3 px-5 py-3.5 transition-colors ${!n.read ? "bg-accent/4" : ""}`}
              >
                {/* Sender avatar */}
                <Link href={`/profile/${n.fromUserId}`} className="shrink-0">
                  <Avatar emoji={n.fromUserAvatar} color={n.fromUserColor} size="md" />
                </Link>

                {/* Text */}
                <div className="flex-1 min-w-0">
                  <p className="text-sm text-ink leading-snug">
                    <Link href={`/profile/${n.fromUserId}`} className="font-semibold hover:underline">
                      {n.fromUserName}
                    </Link>
                    {" "}
                    <span className="text-ink-muted">{meta.label}</span>
                  </p>
                  <p className="text-xs text-ink-subtle mt-0.5">{formatRelativeTime(n.createdAt)}</p>
                </div>

                {/* Type icon */}
                <div
                  className="w-8 h-8 rounded-full flex items-center justify-center shrink-0"
                  style={{ backgroundColor: meta.color + "18", color: meta.color }}
                >
                  {meta.icon}
                </div>

                {/* Post thumbnail */}
                {n.postId && n.postImageUrl && (
                  <Link href={`/post/${n.postId}`} className="shrink-0">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={n.postImageUrl}
                      alt="post"
                      className="w-11 h-11 rounded-[10px] object-cover border border-rim"
                    />
                  </Link>
                )}
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
