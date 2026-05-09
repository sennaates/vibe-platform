"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import Image from "next/image"
import { signInWithEmailAndPassword, createUserWithEmailAndPassword } from "firebase/auth"
import { doc, setDoc, serverTimestamp } from "firebase/firestore"
import { auth, db } from "@/lib/firebase"
import { profileColors } from "@/lib/design"
import { cn } from "@/lib/utils"

const EMOJIS = ["🎨","🌊","⚡","🌸","🔥","🌙","🦋","🎭","🌿","💫","🎵","🦊"]
const COLOR_KEYS = Object.keys(profileColors)

export default function AuthPage() {
  const router = useRouter()
  const [mode, setMode]         = useState<"login" | "signup">("login")
  const [step, setStep]         = useState(1)
  const [email, setEmail]       = useState("")
  const [password, setPassword] = useState("")
  const [displayName, setName]  = useState("")
  const [emoji, setEmoji]       = useState("🎨")
  const [color, setColor]       = useState("blue")
  const [error, setError]       = useState("")
  const [loading, setLoading]   = useState(false)

  async function handleLogin() {
    setError(""); setLoading(true)
    try { await signInWithEmailAndPassword(auth, email, password); router.push("/") }
    catch { setError("E-posta veya şifre hatalı.") }
    finally { setLoading(false) }
  }

  async function handleSignup() {
    setError(""); setLoading(true)
    try {
      const cred = await createUserWithEmailAndPassword(auth, email, password)
      await setDoc(doc(db, "users", cred.user.uid), {
        uid: cred.user.uid, email, displayName, avatarEmoji: emoji,
        profileColor: color, bio: "", followersCount: 0, followingCount: 0,
        postsCount: 0, createdAt: serverTimestamp(),
      })
      router.push("/")
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : ""
      if (msg.includes("email-already-in-use")) setError("Bu e-posta zaten kullanımda.")
      else if (msg.includes("weak-password")) setError("Şifre en az 6 karakter olmalı.")
      else setError("Bir hata oluştu, tekrar dene.")
    } finally { setLoading(false) }
  }

  const selectedColor = profileColors[color] ?? "#4A7FA5"

  return (
    <div className="min-h-[calc(100vh-56px)] flex">
      {/* Sol — dekoratif panel (sadece lg+) */}
      <div
        className="hidden lg:flex lg:w-1/2 xl:w-3/5 items-center justify-center relative"
        style={{ background: "linear-gradient(135deg, #D9723F18, #7C5CBF12, #4A7FA510)" }}
      >
        <div className="text-center max-w-md px-8">
          <div className="w-24 h-24 rounded-3xl overflow-hidden shadow-lg mx-auto mb-8">
            <Image src="/logo.png" alt="Vibe" width={96} height={96} />
          </div>
          <h2 className="text-3xl xl:text-4xl font-bold text-ink mb-3">Duygularınla çiz</h2>
          <p className="text-ink-muted text-base leading-relaxed">
            Kalp atışın ve duyguların fırçanı şekillendirir. Her çizim, o anki hissinin yansıması.
          </p>
          <div className="flex justify-center gap-3 mt-8">
            {["🌊","⚡","🌸","🔥","🌙"].map(e => (
              <span key={e} className="w-10 h-10 rounded-full bg-surface/60 flex items-center justify-center text-xl shadow-sm">{e}</span>
            ))}
          </div>
        </div>
      </div>

      {/* Sağ — form */}
      <div className="flex-1 flex items-center justify-center px-4 sm:px-8 py-10">
        <div className="w-full max-w-sm">
          {/* Mobile logo */}
          <div className="flex flex-col items-center mb-8 lg:hidden">
            <div className="w-16 h-16 rounded-2xl bg-accent flex items-center justify-center mb-4 shadow-md">
              <Image src="/logo.png" alt="Vibe" width={40} height={40} className="rounded-xl" />
            </div>
          </div>

          <h1 className="text-2xl font-bold text-ink text-center lg:text-left">
            {mode === "login" ? "Tekrar hoş geldin" : "Vibe&apos;a katıl"}
          </h1>
          <p className="text-sm text-ink-muted mt-1.5 text-center lg:text-left mb-6">
            {mode === "login" ? "Hesabına giriş yap" : "Ücretsiz hesap oluştur"}
          </p>

          {mode === "signup" && (
            <div className="flex items-center gap-1.5 mb-6">
              <div className={cn("flex-1 h-1.5 rounded-full transition-colors", step >= 1 ? "bg-accent" : "bg-rim")} />
              <div className={cn("flex-1 h-1.5 rounded-full transition-colors", step === 2 ? "bg-accent" : "bg-rim")} />
            </div>
          )}

          <div className="bg-surface border border-rim rounded-[22px] p-6 shadow-sm">
            {mode === "login" && (
              <div className="flex flex-col gap-4">
                <Field label="E-posta" type="email" value={email} onChange={setEmail} placeholder="sen@ornek.com" />
                <Field label="Şifre" type="password" value={password} onChange={setPassword} placeholder="••••••" />
                {error && <p className="text-red-500 text-xs bg-red-50 px-3 py-2 rounded-[10px]">{error}</p>}
                <button onClick={handleLogin} disabled={loading}
                  className="w-full py-3 bg-accent text-white rounded-[14px] font-semibold text-sm hover:bg-accent-hover disabled:opacity-50 transition-all active:scale-[0.98]">
                  {loading ? "Giriş yapılıyor…" : "Giriş Yap"}
                </button>
              </div>
            )}

            {mode === "signup" && step === 1 && (
              <div className="flex flex-col gap-4">
                <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest">Adım 1 / 2</p>
                <Field label="Adın" type="text" value={displayName} onChange={setName} placeholder="Adın" />
                <Field label="E-posta" type="email" value={email} onChange={setEmail} placeholder="sen@ornek.com" />
                <Field label="Şifre" type="password" value={password} onChange={setPassword} placeholder="En az 6 karakter" />
                {error && <p className="text-red-500 text-xs bg-red-50 px-3 py-2 rounded-[10px]">{error}</p>}
                <button onClick={() => { if (!displayName || !email || password.length < 6) { setError("Tüm alanları doldur."); return }; setError(""); setStep(2) }}
                  className="w-full py-3 bg-accent text-white rounded-[14px] font-semibold text-sm hover:bg-accent-hover transition-all active:scale-[0.98]">
                  Devam
                </button>
              </div>
            )}

            {mode === "signup" && step === 2 && (
              <div className="flex flex-col gap-5">
                <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest">Adım 2 / 2</p>
                <div className="flex flex-col items-center gap-2">
                  <div className="w-16 h-16 rounded-full flex items-center justify-center text-3xl shadow-sm border-2 border-white"
                    style={{ backgroundColor: selectedColor + "20", outline: `2px solid ${selectedColor}`, outlineOffset: "2px" }}>
                    {emoji}
                  </div>
                  <p className="text-xs text-ink-subtle">Avatarın</p>
                </div>
                <div>
                  <p className="text-xs font-semibold text-ink-muted mb-2.5">Emoji seç</p>
                  <div className="grid grid-cols-6 gap-2">
                    {EMOJIS.map(e => (
                      <button key={e} onClick={() => setEmoji(e)} className={cn(
                        "h-10 rounded-[10px] text-xl transition-all active:scale-90",
                        emoji === e ? "bg-accent/15 ring-2 ring-accent/50 scale-110" : "bg-surface-muted hover:bg-[#EDE9E3]"
                      )}>{e}</button>
                    ))}
                  </div>
                </div>
                <div>
                  <p className="text-xs font-semibold text-ink-muted mb-2.5">Renk seç</p>
                  <div className="flex flex-wrap gap-2.5">
                    {COLOR_KEYS.map(k => (
                      <button key={k} onClick={() => setColor(k)} className={cn(
                        "w-7 h-7 rounded-full transition-all",
                        color === k ? "scale-125 ring-2 ring-offset-2 ring-accent" : "hover:scale-110"
                      )} style={{ backgroundColor: profileColors[k] }} />
                    ))}
                  </div>
                </div>
                {error && <p className="text-red-500 text-xs bg-red-50 px-3 py-2 rounded-[10px]">{error}</p>}
                <div className="flex gap-2">
                  <button onClick={() => setStep(1)}
                    className="flex-1 py-3 bg-surface border border-rim text-ink rounded-[14px] font-semibold text-sm hover:bg-surface-muted transition-colors">
                    Geri
                  </button>
                  <button onClick={handleSignup} disabled={loading}
                    className="flex-1 py-3 bg-accent text-white rounded-[14px] font-semibold text-sm hover:bg-accent-hover disabled:opacity-50 transition-all">
                    {loading ? "Oluşturuluyor…" : "Başla"}
                  </button>
                </div>
              </div>
            )}
          </div>

          <p className="text-center text-sm text-ink-muted mt-5">
            {mode === "login" ? "Hesabın yok mu?" : "Zaten hesabın var mı?"}{" "}
            <button onClick={() => { setMode(mode === "login" ? "signup" : "login"); setStep(1); setError("") }}
              className="text-accent font-medium hover:underline">
              {mode === "login" ? "Kayıt ol" : "Giriş yap"}
            </button>
          </p>
        </div>
      </div>
    </div>
  )
}

function Field({ label, type, value, onChange, placeholder }: {
  label: string; type: string; value: string; onChange: (v: string) => void; placeholder: string
}) {
  return (
    <div>
      <label className="block text-xs font-medium text-ink-muted mb-1.5">{label}</label>
      <input type={type} value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder}
        className="w-full px-4 py-3 rounded-[14px] bg-canvas border border-rim text-ink text-sm placeholder:text-ink-subtle focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent transition" />
    </div>
  )
}
