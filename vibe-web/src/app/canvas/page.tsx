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
    const imageUrl = await uploadToCloudinary(dataUrl)

    if (!imageUrl) {
      toast.error("Görsel yüklenemedi. Bağlantını kontrol et ve tekrar dene.")
      return          // ← kaydetmiyoruz, kullanıcı retry yapabilir
    }

    // 2. Hashtag çıkar
    const tags = extractTags(caption)

    // 3. Firestore'a kaydet
    try {
      await addDoc(collection(db, "posts"), {
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
      })

      // 4. postsCount artır
      await updateDoc(doc(db, "users", user.uid), { postsCount: increment(1) })

      toast.success("Çizim paylaşıldı! 🎉")
      router.push("/")
    } catch (e) {
      console.error("Firestore kayıt hatası:", e)
      toast.error("Gönderi kaydedilemedi. Tekrar dene.")
    }
  }

  if (!emotion) {
    return <EmotionPicker onSelect={(e, b, bgType) => { setEmotion(e); setBpm(b); setBg(bgType) }} />
  }

  return (
    <DrawingCanvas
      emotion={emotion}
      bpm={bpm}
      bg={bg}
      onSave={handleSave}
      onDiscard={() => setEmotion(null)}
    />
  )
}
