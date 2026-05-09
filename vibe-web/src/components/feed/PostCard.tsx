"use client"

import Link from "next/link"
import Image from "next/image"
import { Heart, MessageCircle, MoreHorizontal, Trash2, Link2 } from "lucide-react"
import { useState } from "react"
import { doc, updateDoc, increment, setDoc, deleteDoc } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { Avatar } from "@/components/ui/Avatar"
import { profileColors } from "@/lib/design"
import { formatRelativeTime } from "@/lib/utils"
import { createNotification } from "@/lib/notifications"
import { toast } from "@/lib/toast"
import type { Post } from "@/types"

interface PostCardProps {
  post: Post
  isLiked?: boolean
  onDeleted?: (id: string) => void
}

export function PostCard({ post, isLiked: initialLiked = false, onDeleted }: PostCardProps) {
  const { user, profile } = useAuth()
  const [liked, setLiked]     = useState(initialLiked)
  const [likes, setLikes]     = useState(post.likesCount)
  const [showMenu, setShowMenu] = useState(false)
  const [deleted, setDeleted] = useState(false)

  const isOwn = user?.uid === post.userId

  const accent = profileColors[post.userColor] ?? "#4A7FA5"

  // Parse emotion text — may be "Mutlu ☀️" or just the label
  const emotionParts = post.emotion.split(" ")
  const emotionLabel = emotionParts[0]
  const emotionEmoji = emotionParts[1] ?? "🎨"

  async function handleDelete() {
    await deleteDoc(doc(db, "posts", post.id))
    await updateDoc(doc(db, "users", post.userId), { postsCount: increment(-1) })
    setDeleted(true)
    onDeleted?.(post.id)
  }

  if (deleted) return null

  async function toggleLike() {
    if (!user) return
    const likeRef    = doc(db, "posts", post.id, "likes", user.uid)
    const postRef    = doc(db, "posts", post.id)
    const userLikeRef = doc(db, "userLikes", user.uid, "items", post.id)

    if (liked) {
      await deleteDoc(likeRef)
      await deleteDoc(userLikeRef)
      await updateDoc(postRef, { likesCount: increment(-1) })
      setLiked(false)
      setLikes(l => l - 1)
    } else {
      await setDoc(likeRef, { userId: user.uid, createdAt: new Date() })
      await setDoc(userLikeRef, { postId: post.id, likedAt: new Date() })
      await updateDoc(postRef, { likesCount: increment(1) })
      setLiked(true)
      setLikes(l => l + 1)
      if (profile) {
        await createNotification({
          targetUserId:   post.userId,
          type:           "like",
          fromUserId:     user.uid,
          fromUserName:   profile.displayName,
          fromUserAvatar: profile.avatarEmoji,
          fromUserColor:  profile.profileColor,
          postId:         post.id,
          postImageUrl:   post.imageUrl,
        })
      }
    }
  }

  return (
    <article className="bg-white border border-[#E8E4DC] rounded-[18px] overflow-hidden shadow-sm">
      {/* Header */}
      <div className="flex items-center gap-3 px-5 pt-5 pb-3">
        <Link href={`/profile/${post.userId}`} className="shrink-0">
          <Avatar emoji={post.userAvatar} color={post.userColor} size="md" />
        </Link>

        <div className="flex-1 min-w-0">
          <Link
            href={`/profile/${post.userId}`}
            className="font-semibold text-[#1C1917] text-sm hover:underline truncate block leading-tight"
          >
            {post.userName}
          </Link>
          <p className="text-xs text-[#A8A29E] mt-0.5">{formatRelativeTime(post.createdAt)}</p>
        </div>

        {/* Chips + menu */}
        <div className="flex items-center gap-2 shrink-0">
          {/* Emotion chip */}
          <span
            className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium"
            style={{ backgroundColor: accent + "18", color: accent }}
          >
            <span>{emotionEmoji}</span>
            <span>{emotionLabel}</span>
          </span>

          {/* BPM badge */}
          {post.bpm > 0 && (
            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-[#F5F3EF] text-[#78716C]">
              <span className="text-[10px]">♥</span>
              {post.bpm}
            </span>
          )}

          {/* Own post menu */}
          {isOwn && (
            <div className="relative">
              <button
                onClick={() => setShowMenu(m => !m)}
                className="p-1.5 rounded-[8px] text-[#A8A29E] hover:bg-[#F5F3EF] hover:text-[#78716C] transition-colors"
              >
                <MoreHorizontal size={15} />
              </button>
              {showMenu && (
                <>
                  <div className="fixed inset-0 z-10" onClick={() => setShowMenu(false)} />
                  <div className="absolute right-0 top-8 z-20 bg-white border border-[#E8E4DC] rounded-[14px] shadow-lg py-1 min-w-[130px]">
                    <button
                      onClick={() => { setShowMenu(false); handleDelete() }}
                      className="w-full flex items-center gap-2.5 px-4 py-2.5 text-sm font-medium text-red-500 hover:bg-red-50 transition-colors"
                    >
                      <Trash2 size={13} />
                      Sil
                    </button>
                  </div>
                </>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Drawing image — full width */}
      <Link href={`/post/${post.id}`} className="block">
        <div
          className="w-full aspect-square relative overflow-hidden"
          style={{ background: `linear-gradient(135deg, ${accent}20, ${accent}08)` }}
        >
          {post.imageUrl && (
            <Image
              src={post.imageUrl}
              alt={post.emotion}
              fill
              className="object-cover"
              sizes="(max-width: 672px) 100vw, 672px"
            />
          )}
        </div>
      </Link>

      {/* Actions row */}
      <div className="flex items-center gap-4 px-5 py-3">
        <button
          onClick={toggleLike}
          className="flex items-center gap-1.5 text-sm font-medium transition-all active:scale-90"
          style={{ color: liked ? "#e53e3e" : "#A8A29E" }}
          aria-label={liked ? "Beğeniyi kaldır" : "Beğen"}
        >
          <Heart size={19} className={liked ? "fill-red-500" : ""} />
          <span>{likes}</span>
        </button>

        <Link
          href={`/post/${post.id}`}
          className="flex items-center gap-1.5 text-sm font-medium text-[#A8A29E] hover:text-[#78716C] transition-colors"
        >
          <MessageCircle size={19} />
          <span>{post.commentsCount}</span>
        </Link>

        <button
          onClick={() => {
            const url = `${window.location.origin}/post/${post.id}`
            navigator.clipboard.writeText(url).then(() => toast.success("Link kopyalandı!"))
          }}
          className="ml-auto text-[#A8A29E] hover:text-[#78716C] transition-colors"
          aria-label="Paylaş"
        >
          <Link2 size={18} />
        </button>
      </div>

      {/* Caption */}
      {post.caption && (
        <p className="px-5 pb-5 text-sm text-[#1C1917] leading-relaxed -mt-1">
          {post.caption}
        </p>
      )}
    </article>
  )
}
