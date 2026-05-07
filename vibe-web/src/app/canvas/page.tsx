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
import type { EmotionState } from "@/lib/drawingEngine"

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
        <p className="text-[#1C1917] font-semibold">Çizmek için giriş yap</p>
        <button
          onClick={() => router.push("/auth")}
          className="px-4 py-2 bg-[#D9723F] text-white rounded-[14px] text-sm font-medium"
        >
          Giriş Yap
        </button>
      </div>
    )
  }

  async function handleSave(dataUrl: string, caption: string) {
    if (!user || !profile) return

    // Cloudinary'ye yükle
    const formData = new FormData()
    const blob = await (await fetch(dataUrl)).blob()
    formData.append("file", blob, "drawing.png")
    formData.append("upload_preset", "vibe_drawings")
    formData.append("folder", "vibe")

    let imageUrl = ""
    try {
      const res = await fetch(
        `https://api.cloudinary.com/v1_1/${process.env.NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME}/image/upload`,
        { method: "POST", body: formData }
      )
      const data = await res.json()
      imageUrl = data.secure_url ?? ""
    } catch {
      // Cloudinary yoksa dataUrl kullan (geçici)
      imageUrl = dataUrl
    }

    // Firestore'a kaydet
    await addDoc(collection(db, "posts"), {
      userId:        user.uid,
      userName:      profile.displayName,
      userAvatar:    profile.avatarEmoji,
      userColor:     profile.profileColor,
      imageUrl,
      emotion:       emotion!.label + " " + emotion!.emoji,
      bpm,
      caption,
      likesCount:    0,
      commentsCount: 0,
      createdAt:     serverTimestamp(),
    })

    // postsCount artır
    await updateDoc(doc(db, "users", user.uid), { postsCount: increment(1) })

    router.push("/")
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
