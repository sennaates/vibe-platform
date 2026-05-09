"use client"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { doc, updateDoc } from "firebase/firestore"
import { ArrowLeft, Check } from "lucide-react"
import Link from "next/link"
import { db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { profileColors } from "@/lib/design"
import { cn } from "@/lib/utils"

const EMOJIS = ["🎨","🌊","⚡","🌸","🔥","🌙","🦋","🎭","🌿","💫","🎵","🦊","🐉","🌈","🍀","🦄","🎯","🔮","🎸","🌺"]
const COLOR_KEYS = Object.keys(profileColors)

export default function EditProfilePage() {
  const { user, profile, loading } = useAuth()
  const router = useRouter()

  const [displayName, setName] = useState("")
  const [bio, setBio]          = useState("")
  const [emoji, setEmoji]      = useState("🎨")
  const [color, setColor]      = useState("blue")
  const [saving, setSaving]    = useState(false)

  useEffect(() => {
    if (profile) {
      setName(profile.displayName)
      setBio(profile.bio ?? "")
      setEmoji(profile.avatarEmoji)
      setColor(profile.profileColor)
    }
  }, [profile])

  useEffect(() => {
    if (!loading && !user) router.push("/auth")
  }, [loading, user, router])

  async function handleSave() {
    if (!user || !displayName.trim()) return
    setSaving(true)
    await updateDoc(doc(db, "users", user.uid), {
      displayName: displayName.trim(),
      bio: bio.trim(),
      avatarEmoji: emoji,
      profileColor: color,
    })
    router.push(`/profile/${user.uid}`)
  }

  if (loading || !profile) {
    return (
      <div className="max-w-2xl mx-auto px-4 py-8 animate-pulse space-y-4">
        <div className="h-6 w-24 bg-rim rounded-full" />
        <div className="h-40 bg-rim rounded-[22px]" />
      </div>
    )
  }

  const selectedColor = profileColors[color] ?? "#4A7FA5"

  return (
    <div className="max-w-xl mx-auto px-4 py-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <Link href={`/profile/${user?.uid}`}
          className="flex items-center gap-1.5 text-sm text-ink-muted hover:text-ink transition-colors font-medium">
          <ArrowLeft size={16} />
          Geri
        </Link>
        <h1 className="text-base font-bold text-ink">Profili Düzenle</h1>
        <button onClick={handleSave} disabled={saving || !displayName.trim()}
          className="flex items-center gap-1.5 px-4 py-1.5 bg-accent text-white rounded-full text-sm font-semibold disabled:opacity-40 transition-all active:scale-95">
          <Check size={14} strokeWidth={2.5} />
          {saving ? "Kaydediliyor…" : "Kaydet"}
        </button>
      </div>

      {/* Avatar önizleme */}
      <div className="flex flex-col items-center mb-6">
        <div
          className="w-20 h-20 rounded-full flex items-center justify-center text-4xl shadow-md border-4 border-white transition-all"
          style={{ backgroundColor: selectedColor + "25", outline: `3px solid ${selectedColor}30`, outlineOffset: "2px" }}
        >
          {emoji}
        </div>
        <p className="text-xs text-ink-subtle mt-2">{displayName || "Adın"}</p>
      </div>

      <div className="space-y-4">
        {/* Ad */}
        <div className="bg-surface border border-rim rounded-[22px] p-5 shadow-sm">
          <label className="block text-xs font-semibold text-ink-subtle uppercase tracking-widest mb-3">Bilgiler</label>
          <div className="space-y-3">
            <div>
              <label className="block text-xs font-medium text-ink-muted mb-1.5">Ad</label>
              <input type="text" value={displayName} onChange={e => setName(e.target.value)} placeholder="Adın"
                className="w-full px-4 py-2.5 rounded-[12px] bg-canvas border border-rim text-sm text-ink placeholder:text-ink-subtle focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent transition" />
            </div>
            <div>
              <label className="block text-xs font-medium text-ink-muted mb-1.5">Bio</label>
              <textarea value={bio} onChange={e => setBio(e.target.value)} placeholder="Kendin hakkında bir şey yaz…" rows={2}
                className="w-full px-4 py-2.5 rounded-[12px] bg-canvas border border-rim text-sm text-ink placeholder:text-ink-subtle focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent resize-none transition" />
            </div>
          </div>
        </div>

        {/* Emoji */}
        <div className="bg-surface border border-rim rounded-[22px] p-5 shadow-sm">
          <label className="block text-xs font-semibold text-ink-subtle uppercase tracking-widest mb-3">Avatar Emoji</label>
          <div className="grid grid-cols-10 gap-1.5">
            {EMOJIS.map(e => (
              <button key={e} onClick={() => setEmoji(e)}
                className={cn(
                  "h-10 rounded-[10px] text-xl transition-all active:scale-90",
                  emoji === e ? "scale-110 ring-2 ring-accent/40" : "bg-surface-muted hover:bg-[#EDE9E3]"
                )}
                style={emoji === e ? { backgroundColor: selectedColor + "20" } : {}}>
                {e}
              </button>
            ))}
          </div>
        </div>

        {/* Renk */}
        <div className="bg-surface border border-rim rounded-[22px] p-5 shadow-sm">
          <label className="block text-xs font-semibold text-ink-subtle uppercase tracking-widest mb-3">Profil Rengi</label>
          <div className="flex flex-wrap gap-3">
            {COLOR_KEYS.map(k => (
              <button key={k} onClick={() => setColor(k)}
                className={cn("w-9 h-9 rounded-full transition-all active:scale-90", color === k ? "scale-125 ring-2 ring-offset-2 ring-accent" : "hover:scale-110")}
                style={{ backgroundColor: profileColors[k] }} />
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
