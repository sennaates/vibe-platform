"use client"

import { use, useEffect, useRef, useState } from "react"
import Image from "next/image"
import Link from "next/link"
import { useRouter } from "next/navigation"
import {
  doc, getDoc, collection, query, orderBy,
  onSnapshot, addDoc, serverTimestamp, updateDoc, increment, deleteDoc,
  setDoc
} from "firebase/firestore"
import { ArrowLeft, Send, Heart, Trash2, MoreHorizontal, MessageCircle } from "lucide-react"
import { db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { Avatar } from "@/components/ui/Avatar"
import { profileColors } from "@/lib/design"
import { formatRelativeTime } from "@/lib/utils"
import { createNotification } from "@/lib/notifications"
import type { Post, Comment } from "@/types"

export default function PostDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params)
  const { user, profile } = useAuth()
  const router = useRouter()

  const [post, setPost]           = useState<Post | null>(null)
  const [comments, setComments]   = useState<Comment[]>([])
  const [text, setText]           = useState("")
  const [sending, setSending]     = useState(false)
  const [deleting, setDeleting]   = useState(false)
  const [showMenu, setShowMenu]   = useState(false)
  const [liked, setLiked]         = useState(false)
  const [likes, setLikes]         = useState(0)
  const bottomRef                 = useRef<HTMLDivElement>(null)

  useEffect(() => {
    getDoc(doc(db, "posts", id)).then(snap => {
      if (snap.exists()) {
        const data = { id: snap.id, ...snap.data() } as Post
        setPost(data)
        setLikes(data.likesCount)
      }
    })
  }, [id])

  // Check if current user liked this post
  useEffect(() => {
    if (!user) return
    getDoc(doc(db, "posts", id, "likes", user.uid)).then(snap => setLiked(snap.exists()))
  }, [id, user])

  useEffect(() => {
    const q = query(collection(db, "posts", id, "comments"), orderBy("createdAt", "asc"))
    return onSnapshot(q, snap => {
      setComments(snap.docs.map(d => ({ id: d.id, ...d.data() } as Comment)))
    })
  }, [id])

  const isOwnPost = user?.uid === post?.userId

  async function toggleLike() {
    if (!user || !post) return
    const likeRef = doc(db, "posts", id, "likes", user.uid)
    const postRef = doc(db, "posts", id)
    if (liked) {
      await deleteDoc(likeRef)
      await updateDoc(postRef, { likesCount: increment(-1) })
      setLiked(false)
      setLikes(l => l - 1)
    } else {
      await setDoc(likeRef, { userId: user.uid, createdAt: new Date() })
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
          postId:         id,
          postImageUrl:   post.imageUrl,
        })
      }
    }
  }

  async function handleDelete() {
    if (!post || !user || !isOwnPost) return
    setDeleting(true)
    await deleteDoc(doc(db, "posts", id))
    await updateDoc(doc(db, "users", post.userId), { postsCount: increment(-1) })
    router.push(`/profile/${user.uid}`)
  }

  async function sendComment() {
    if (!text.trim() || !user || !profile || sending) return
    setSending(true)
    await addDoc(collection(db, "posts", id, "comments"), {
      userId: user.uid, userName: profile.displayName,
      userAvatar: profile.avatarEmoji, userColor: profile.profileColor,
      text: text.trim(), createdAt: serverTimestamp(),
    })
    await updateDoc(doc(db, "posts", id), { commentsCount: increment(1) })
    // notify post owner
    if (post) {
      await createNotification({
        targetUserId:   post.userId,
        type:           "comment",
        fromUserId:     user.uid,
        fromUserName:   profile.displayName,
        fromUserAvatar: profile.avatarEmoji,
        fromUserColor:  profile.profileColor,
        postId:         id,
        postImageUrl:   post.imageUrl,
      })
    }
    setText("")
    setSending(false)
    setTimeout(() => bottomRef.current?.scrollIntoView({ behavior: "smooth" }), 100)
  }

  if (!post) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 animate-pulse">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="aspect-square bg-[#E8E4DC] rounded-[18px]" />
          <div className="bg-[#E8E4DC] rounded-[18px] h-96" />
        </div>
      </div>
    )
  }

  const accent = profileColors[post.userColor] ?? "#4A7FA5"
  const emotionParts = post.emotion.split(" ")

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-6">
      {/* Geri */}
      <Link
        href="/"
        className="inline-flex items-center gap-1.5 text-sm text-[#78716C] hover:text-[#1C1917] mb-4 transition-colors font-medium"
      >
        <ArrowLeft size={16} />
        Geri
      </Link>

      {/* Desktop: yan yana, mobile: üst üste */}
      <div className="grid grid-cols-1 lg:grid-cols-5 gap-5 lg:gap-6">
        {/* Sol — çizim (3/5) */}
        <div className="lg:col-span-3">
          <div className="bg-white border border-[#E8E4DC] rounded-[22px] overflow-hidden shadow-sm sticky top-20">
            {/* Header */}
            <div className="flex items-center gap-3 px-5 pt-5 pb-3">
              <Link href={`/profile/${post.userId}`}>
                <Avatar emoji={post.userAvatar} color={post.userColor} size="lg" />
              </Link>
              <div className="flex-1 min-w-0">
                <Link href={`/profile/${post.userId}`} className="font-semibold text-[#1C1917] hover:underline block">
                  {post.userName}
                </Link>
                <p className="text-xs text-[#A8A29E]">{formatRelativeTime(post.createdAt)}</p>
              </div>
              <div className="flex items-center gap-2">
                <span
                  className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium"
                  style={{ backgroundColor: accent + "18", color: accent }}
                >
                  {emotionParts[1] ?? "🎨"} {emotionParts[0]}
                </span>
                {post.bpm > 0 && (
                  <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-[#F5F3EF] text-[#78716C]">
                    <Heart size={10} className="fill-[#C45F8A] text-[#C45F8A]" /> {post.bpm}
                  </span>
                )}
                {isOwnPost && (
                  <div className="relative">
                    <button
                      onClick={() => setShowMenu(m => !m)}
                      className="p-1.5 rounded-[8px] text-[#A8A29E] hover:bg-[#F5F3EF] hover:text-[#78716C] transition-colors"
                    >
                      <MoreHorizontal size={16} />
                    </button>
                    {showMenu && (
                      <>
                        <div className="fixed inset-0 z-10" onClick={() => setShowMenu(false)} />
                        <div className="absolute right-0 top-8 z-20 bg-white border border-[#E8E4DC] rounded-[14px] shadow-lg py-1 min-w-[140px]">
                          <button
                            onClick={() => { setShowMenu(false); handleDelete() }}
                            disabled={deleting}
                            className="w-full flex items-center gap-2.5 px-4 py-2.5 text-sm font-medium text-red-500 hover:bg-red-50 transition-colors"
                          >
                            <Trash2 size={14} />
                            {deleting ? "Siliniyor…" : "Çizimi Sil"}
                          </button>
                        </div>
                      </>
                    )}
                  </div>
                )}
              </div>
            </div>

            {/* Çizim */}
            <div
              className="w-full aspect-square relative"
              style={{ background: `linear-gradient(135deg, ${accent}20, ${accent}08)` }}
            >
              {post.imageUrl && (
                <Image src={post.imageUrl} alt={post.emotion} fill className="object-cover" sizes="(max-width: 1024px) 100vw, 60vw" />
              )}
            </div>

            {/* Actions row */}
            <div className="flex items-center gap-5 px-5 pt-3 pb-1">
              <button
                onClick={toggleLike}
                className="flex items-center gap-1.5 text-sm font-medium transition-all active:scale-90"
                style={{ color: liked ? "#e53e3e" : "#A8A29E" }}
              >
                <Heart size={20} className={liked ? "fill-red-500" : ""} />
                <span>{likes}</span>
              </button>
              <div className="flex items-center gap-1.5 text-sm font-medium text-[#A8A29E]">
                <MessageCircle size={20} />
                <span>{comments.length}</span>
              </div>
            </div>

            {/* Caption */}
            {post.caption && (
              <p className="px-5 py-3 text-sm text-[#1C1917] leading-relaxed">{post.caption}</p>
            )}
          </div>
        </div>

        {/* Sağ — yorumlar (2/5) */}
        <div className="lg:col-span-2">
          <div className="bg-white border border-[#E8E4DC] rounded-[22px] overflow-hidden shadow-sm lg:sticky lg:top-20 flex flex-col lg:max-h-[calc(100vh-120px)]">
            <div className="px-5 py-4 border-b border-[#E8E4DC] shrink-0">
              <h2 className="font-semibold text-[#1C1917]">
                Yorumlar{" "}
                {comments.length > 0 && (
                  <span className="text-[#A8A29E] font-normal text-sm">({comments.length})</span>
                )}
              </h2>
            </div>

            <div className="flex-1 overflow-y-auto divide-y divide-[#F5F3EF]">
              {comments.length === 0 ? (
                <div className="px-5 py-16 text-center">
                  <span className="text-3xl block mb-2">💬</span>
                  <p className="text-sm text-[#78716C]">Henüz yorum yok</p>
                  <p className="text-xs text-[#A8A29E] mt-0.5">İlk sen yaz</p>
                </div>
              ) : (
                comments.map(c => (
                  <div key={c.id} className="flex gap-3 px-5 py-3.5 group">
                    <Avatar emoji={c.userAvatar} color={c.userColor} size="sm" className="mt-0.5 shrink-0" />
                    <div className="min-w-0 flex-1">
                      <div className="flex items-baseline gap-1.5">
                        <span className="text-xs font-semibold text-[#1C1917]">{c.userName}</span>
                        <span className="text-[10px] text-[#A8A29E]">{formatRelativeTime(c.createdAt)}</span>
                        {/* Delete own comment */}
                        {user?.uid === c.userId && (
                          <button
                            onClick={async () => {
                              await deleteDoc(doc(db, "posts", id, "comments", c.id))
                              await updateDoc(doc(db, "posts", id), { commentsCount: increment(-1) })
                            }}
                            className="ml-auto opacity-0 group-hover:opacity-100 transition-opacity p-1 rounded text-[#A8A29E] hover:text-red-400"
                          >
                            <Trash2 size={11} />
                          </button>
                        )}
                      </div>
                      <p className="text-sm text-[#1C1917] mt-0.5 leading-relaxed break-words">{c.text}</p>
                    </div>
                  </div>
                ))
              )}
              <div ref={bottomRef} />
            </div>

            {/* Yorum gir */}
            {user && profile ? (
              <div className="flex items-center gap-3 px-4 py-3 border-t border-[#E8E4DC] shrink-0 bg-[#FAF8F4]/50">
                <Avatar emoji={profile.avatarEmoji} color={profile.profileColor} size="sm" />
                <div className="flex-1 flex items-center gap-2 bg-white border border-[#E8E4DC] rounded-full px-4 py-2">
                  <input
                    value={text}
                    onChange={e => setText(e.target.value)}
                    onKeyDown={e => e.key === "Enter" && sendComment()}
                    placeholder="Yorum yaz…"
                    className="flex-1 bg-transparent text-sm text-[#1C1917] placeholder:text-[#A8A29E] focus:outline-none min-w-0"
                  />
                  <button
                    onClick={sendComment}
                    disabled={!text.trim() || sending}
                    className="text-[#D9723F] disabled:opacity-30 transition-opacity shrink-0"
                  >
                    <Send size={16} />
                  </button>
                </div>
              </div>
            ) : (
              <div className="px-5 py-3 border-t border-[#E8E4DC] text-center shrink-0">
                <Link href="/auth" className="text-sm text-[#D9723F] font-medium hover:underline">
                  Yorum yazmak için giriş yap
                </Link>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
