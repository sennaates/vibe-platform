"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import {
  collection, addDoc, serverTimestamp, doc, updateDoc, increment
} from "firebase/firestore"
import { db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { EmotionPicker, type BgType } from "@/components/canvas/EmotionPicker"
import { DrawingCanvas } from "@/components/canvas/DrawingCanvas"
import { toast } from "@/lib/toast"
import type { EmotionState } from "@/lib/drawingEngine"

const CLOUD_NAME    = process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME   ?? ""
const UPLOAD_PRESET = process.env.NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET ?? ""

/** Cloudinary'ye yükle — başarısız olursa null döner */
async function uploadToCloudinary(dataUrl: string): Promise<string | null> {
  if (!CLOUD_NAME || !UPLOAD_PRESET) {
    console.error("Cloudinary env vars eksik: NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME / NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET")
    return null
  }
  try {
    const blob = await (await fetch(dataUrl)).blob()
    const form = new FormData()
    form.append("file", blob, "drawing.png")
    form.append("upload_preset", UPLOAD_PRESET)
    form.append("folder", "vibe")

    const res = await fetch(
      `https://api.cloudinary.com/v1_1/${CLOUD_NAME}/image/upload`,
      { method: "POST", body: form }
    )
    if (!res.ok) {
      const err = await res.json().catch(() => ({}))
      console.error("Cloudinary yükleme hatası:", err)
      return null
    }
    const data = await res.json()
    return data.secure_url ?? null
  } catch (e) {
    console.error("Cloudinary bağlantı hatası:", e)
    return null
  }
}

/** caption'dan #hashtag'leri çıkar */
function extractTags(caption: string): string[] {
  const matches = caption.matchAll(/#([\wÀ-ɏЀ-ӿ]+)/g)
  return [...matches].map(m => m[1].toLowerCase())
}

export default function CanvasPage() {
  const { user, profile } = useAuth()
  const router = useRouter()
  const [emotion, setEmotion] = useState<EmotionState | null>(null)
  const [bpm, setBpm]         = useState(72)
  const [bg, setBg]           = useState<BgType>("blank")
  const [bgColor, setBgColor] = useState("#FAF8F4")

  if (!user || !profile) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[calc(100vh-56px)] gap-4">
        <span className="text-4xl">🎨</span>
        <p className="text-ink font-semibold">Çizmek için giriş yap</p>
        <button
          onClick={() => router.push("/auth")}
          className="px-4 py-2 bg-accent text-white rounded-[14px] text-sm font-medium"
        >
          Giriş Yap
        </button>
      </div>
    )
  }

  /**
   * DrawingCanvas'tan gelen composited dataUrl + caption ile Firestore'a kaydeder.
   * dataUrl iki katmanı (overlay + drawing) zaten birleştirmiş halde gelir.
   */
  async function handleSave(dataUrl: string, caption: string) {
    if (!user || !profile) return

    // 1. Cloudinary'ye yükle
    let imageUrl = await uploadToCloudinary(dataUrl)

    if (!imageUrl) {
      console.warn("Cloudinary upload failed, falling back to base64 data URL.")
      imageUrl = dataUrl // Fallback to raw base64 data
    }

    // 2. Hashtag çıkar
    const tags = extractTags(caption)

    const newPostData = {
      userId:        user.uid,
      userName:      profile.displayName,
      userAvatar:    profile.avatarEmoji,
      userColor:     profile.profileColor,
      imageUrl,
      emotion:       emotion!.label + " " + emotion!.emoji,
      bpm,
      caption:       caption.trim(),
      ...(tags.length > 0 ? { tags } : {}),
      likesCount:    0,
      commentsCount: 0,
      createdAt:     serverTimestamp(),
    }

    // Save to local storage first as a backup for demo/offline
    try {
      const localPosts = JSON.parse(localStorage.getItem("vibe_local_posts") ?? "[]")
      const localPostItem = {
        ...newPostData,
        id: `local-${Date.now()}`,
        createdAt: { seconds: Date.now() / 1000, nanoseconds: 0 }
      }
      localPosts.unshift(localPostItem)
      localStorage.setItem("vibe_local_posts", JSON.stringify(localPosts))
    } catch (e) {
      console.error("Local storage backup save failed:", e)
    }

    // 3. Firestore'a kaydet
    try {
      await addDoc(collection(db, "posts"), newPostData)

      // 4. postsCount artır
      await updateDoc(doc(db, "users", user.uid), { postsCount: increment(1) }).catch(() => {})

      toast.success("Çizim paylaşıldı! 🎉")
      router.push("/")
    } catch (e) {
      console.error("Firestore kayıt hatası:", e)
      toast.success("Çizim yerel olarak paylaşıldı! (Çevrimdışı/Demo Modu) 🎉")
      router.push("/")
    }
  }

  if (!emotion) {
    return <EmotionPicker onSelect={(e, b, bgType, bgVal) => { setEmotion(e); setBpm(b); setBg(bgType); setBgColor(bgVal) }} />
  }

  return (
    <DrawingCanvas
      emotion={emotion}
      bpm={bpm}
      bg={bg}
      bgColor={bgColor}
      onSave={handleSave}
      onDiscard={() => setEmotion(null)}
    />
  )
}
