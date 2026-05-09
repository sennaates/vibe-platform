"use client"

import { useEffect, useState } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import {
  doc, updateDoc, deleteDoc, collection, query,
  where, getDocs, writeBatch
} from "firebase/firestore"
import {
  signOut, updatePassword, updateEmail,
  reauthenticateWithCredential, EmailAuthProvider, deleteUser
} from "firebase/auth"
import {
  User, Bell, Shield, LogOut, Trash2, ChevronRight,
  Lock, Mail, Eye, EyeOff, Check, X, AlertTriangle,
  Info, Pencil
} from "lucide-react"
import { auth, db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { toast } from "@/lib/toast"
import { Avatar } from "@/components/ui/Avatar"

// ─── Reusable primitives ────────────────────────────────────────────────────

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest px-1 mb-2">{title}</p>
      <div className="bg-surface border border-rim rounded-[18px] shadow-sm overflow-hidden divide-y divide-surface-muted">
        {children}
      </div>
    </div>
  )
}

function SettingRow({ icon, label, sublabel, onClick, danger = false, children }: {
  icon: React.ReactNode; label: string; sublabel?: string
  onClick?: () => void; danger?: boolean; children?: React.ReactNode
}) {
  const cls = `flex items-center gap-3.5 px-5 py-4 w-full text-left transition-colors ${onClick ? "hover:bg-canvas cursor-pointer" : ""}`
  const inner = (
    <>
      <span className={`shrink-0 ${danger ? "text-red-400" : "text-ink-muted"}`}>{icon}</span>
      <div className="flex-1 min-w-0">
        <p className={`text-sm font-medium ${danger ? "text-red-500" : "text-ink"}`}>{label}</p>
        {sublabel && <p className="text-xs text-ink-subtle mt-0.5">{sublabel}</p>}
      </div>
      {children}
      {onClick && !children && <ChevronRight size={16} className="text-[#C8C0B4] shrink-0" />}
    </>
  )
  return onClick
    ? <button className={cls} onClick={onClick}>{inner}</button>
    : <div className={cls}>{inner}</div>
}

function Toggle({ value, onChange }: { value: boolean; onChange: (v: boolean) => void }) {
  return (
    <button
      onClick={() => onChange(!value)}
      className={`relative w-11 h-6 rounded-full transition-colors duration-200 shrink-0 ${value ? "bg-accent" : "bg-rim"}`}
    >
      <span className={`absolute top-1 w-4 h-4 bg-surface rounded-full shadow transition-transform duration-200 ${value ? "translate-x-6" : "translate-x-1"}`} />
    </button>
  )
}

function PasswordInput({ label, value, onChange, show, onToggleShow }: {
  label: string; value: string; onChange: (v: string) => void
  show: boolean; onToggleShow: () => void
}) {
  return (
    <div>
      <label className="block text-xs font-medium text-ink-muted mb-1.5">{label}</label>
      <div className="relative">
        <input
          type={show ? "text" : "password"}
          value={value}
          onChange={e => onChange(e.target.value)}
          className="w-full px-4 py-2.5 pr-10 rounded-[12px] bg-canvas border border-rim text-sm text-ink focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent transition"
        />
        <button
          type="button"
          onClick={onToggleShow}
          className="absolute right-3 top-1/2 -translate-y-1/2 text-ink-subtle hover:text-ink-muted"
        >
          {show ? <EyeOff size={15} /> : <Eye size={15} />}
        </button>
      </div>
    </div>
  )
}

// ─── Modals ─────────────────────────────────────────────────────────────────

function Modal({ title, onClose, children }: {
  title: string; onClose: () => void; children: React.ReactNode
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-4 bg-black/40 backdrop-blur-sm">
      <div className="bg-surface rounded-[22px] w-full max-w-sm shadow-xl">
        <div className="flex items-center justify-between px-6 pt-5 pb-4 border-b border-rim">
          <h2 className="font-bold text-ink">{title}</h2>
          <button onClick={onClose} className="p-1.5 rounded-[8px] text-ink-subtle hover:bg-surface-muted">
            <X size={17} />
          </button>
        </div>
        <div className="px-6 py-5 space-y-4">{children}</div>
      </div>
    </div>
  )
}

// ─── Main page ───────────────────────────────────────────────────────────────

export default function SettingsPage() {
  const { user, profile, loading } = useAuth()
  const router = useRouter()

  // Notification toggles
  const [notifFollows,   setNotifFollows]   = useState(true)
  const [notifLikes,     setNotifLikes]     = useState(true)
  const [notifComments,  setNotifComments]  = useState(true)
  const [isPrivate,      setIsPrivate]      = useState(false)
  const [savingPrefs,    setSavingPrefs]    = useState(false)

  // Modal state
  const [modal, setModal] = useState<"password" | "email" | "delete" | null>(null)

  // Change password form
  const [curPass,     setCurPass]     = useState("")
  const [newPass,     setNewPass]     = useState("")
  const [confirmPass, setConfirmPass] = useState("")
  const [showPass,    setShowPass]    = useState(false)
  const [passLoading, setPassLoading] = useState(false)

  // Change email form
  const [newEmail,     setNewEmail]     = useState("")
  const [emailPass,    setEmailPass]    = useState("")
  const [showEPass,    setShowEPass]    = useState(false)
  const [emailLoading, setEmailLoading] = useState(false)

  // Delete account
  const [deletePass,    setDeletePass]    = useState("")
  const [showDeletePass,setShowDeletePass]= useState(false)
  const [deleteConfirm, setDeleteConfirm] = useState("")
  const [deleteLoading, setDeleteLoading] = useState(false)

  useEffect(() => {
    if (!loading && !user) router.push("/auth")
  }, [loading, user, router])

  useEffect(() => {
    if (profile) {
      setNotifFollows(profile.notifFollows  ?? true)
      setNotifLikes(profile.notifLikes    ?? true)
      setNotifComments(profile.notifComments ?? true)
      setIsPrivate(profile.isPrivate ?? false)
    }
  }, [profile])

  async function savePreferences(updates: Record<string, boolean>) {
    if (!user) return
    setSavingPrefs(true)
    await updateDoc(doc(db, "users", user.uid), updates)
    setSavingPrefs(false)
    toast.success("Kaydedildi")
  }

  // ── Change password ──
  async function handleChangePassword() {
    if (!user || !user.email) return
    if (newPass.length < 6) { toast.error("Yeni şifre en az 6 karakter olmalı"); return }
    if (newPass !== confirmPass) { toast.error("Şifreler eşleşmiyor"); return }
    setPassLoading(true)
    try {
      const cred = EmailAuthProvider.credential(user.email, curPass)
      await reauthenticateWithCredential(user, cred)
      await updatePassword(user, newPass)
      toast.success("Şifre değiştirildi")
      setModal(null); setCurPass(""); setNewPass(""); setConfirmPass("")
    } catch {
      toast.error("Mevcut şifre hatalı")
    } finally { setPassLoading(false) }
  }

  // ── Change email ──
  async function handleChangeEmail() {
    if (!user || !user.email) return
    if (!newEmail.includes("@")) { toast.error("Geçerli bir e-posta gir"); return }
    setEmailLoading(true)
    try {
      const cred = EmailAuthProvider.credential(user.email, emailPass)
      await reauthenticateWithCredential(user, cred)
      await updateEmail(user, newEmail)
      await updateDoc(doc(db, "users", user.uid), { email: newEmail })
      toast.success("E-posta değiştirildi")
      setModal(null); setNewEmail(""); setEmailPass("")
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : ""
      if (msg.includes("email-already-in-use")) toast.error("Bu e-posta zaten kullanımda")
      else toast.error("Şifre hatalı veya bir sorun oluştu")
    } finally { setEmailLoading(false) }
  }

  // ── Delete account ──
  async function handleDeleteAccount() {
    if (!user || !user.email) return
    if (deleteConfirm !== "SİL") { toast.error("\"SİL\" yazmanız gerekiyor"); return }
    setDeleteLoading(true)
    try {
      const cred = EmailAuthProvider.credential(user.email, deletePass)
      await reauthenticateWithCredential(user, cred)

      const batch = writeBatch(db)
      // Delete user posts
      const postsSnap = await getDocs(query(collection(db, "posts"), where("userId", "==", user.uid)))
      postsSnap.docs.forEach(d => batch.delete(d.ref))
      // Delete user follows
      const followsSnap = await getDocs(query(collection(db, "follows"), where("followerId", "==", user.uid)))
      followsSnap.docs.forEach(d => batch.delete(d.ref))
      // Delete user doc
      batch.delete(doc(db, "users", user.uid))
      await batch.commit()

      await deleteUser(user)
      router.push("/")
    } catch {
      toast.error("Şifre hatalı veya bir sorun oluştu")
      setDeleteLoading(false)
    }
  }

  async function handleLogout() {
    await signOut(auth)
    router.push("/")
  }

  if (loading || !profile) {
    return (
      <div className="max-w-lg mx-auto px-4 py-8 space-y-4 animate-pulse">
        {[...Array(4)].map((_, i) => (
          <div key={i} className="h-24 bg-rim rounded-[18px]" />
        ))}
      </div>
    )
  }

  return (
    <div className="max-w-lg mx-auto px-4 py-6 sm:py-10 space-y-6">
      <div>
        <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest mb-0.5">Tercihler</p>
        <h1 className="text-2xl font-bold text-ink">Ayarlar</h1>
      </div>

      {/* Profile preview */}
      <div className="bg-surface border border-rim rounded-[18px] p-4 shadow-sm flex items-center gap-4">
        <Avatar emoji={profile.avatarEmoji} color={profile.profileColor} size="lg" />
        <div className="flex-1 min-w-0">
          <p className="font-semibold text-ink truncate">{profile.displayName}</p>
          <p className="text-xs text-ink-subtle truncate">{profile.email}</p>
        </div>
        <Link
          href="/profile/edit"
          className="flex items-center gap-1.5 px-3 py-1.5 bg-surface-muted text-ink-muted rounded-full text-xs font-semibold hover:bg-[#EDE9E3] transition-colors"
        >
          <Pencil size={12} /> Düzenle
        </Link>
      </div>

      {/* Hesap */}
      <Section title="Hesap">
        <SettingRow
          icon={<Lock size={18} />}
          label="Şifre Değiştir"
          sublabel="Hesap güvenliğini güncelle"
          onClick={() => setModal("password")}
        />
        <SettingRow
          icon={<Mail size={18} />}
          label="E-posta Değiştir"
          sublabel={profile.email}
          onClick={() => setModal("email")}
        />
      </Section>

      {/* Bildirimler */}
      <Section title="Bildirimler">
        <SettingRow icon={<Bell size={18} />} label="Takip Bildirimleri" sublabel="Biri seni takip ettiğinde">
          <Toggle
            value={notifFollows}
            onChange={v => { setNotifFollows(v); savePreferences({ notifFollows: v }) }}
          />
        </SettingRow>
        <SettingRow icon={<Bell size={18} />} label="Beğeni Bildirimleri" sublabel="Çizimin beğenildiğinde">
          <Toggle
            value={notifLikes}
            onChange={v => { setNotifLikes(v); savePreferences({ notifLikes: v }) }}
          />
        </SettingRow>
        <SettingRow icon={<Bell size={18} />} label="Yorum Bildirimleri" sublabel="Çizimine yorum geldiğinde">
          <Toggle
            value={notifComments}
            onChange={v => { setNotifComments(v); savePreferences({ notifComments: v }) }}
          />
        </SettingRow>
      </Section>

      {/* Gizlilik */}
      <Section title="Gizlilik">
        <SettingRow
          icon={<Shield size={18} />}
          label="Gizli Hesap"
          sublabel={isPrivate ? "Sadece takipçilerin çizimlerini görebilir" : "Herkes çizimlerini görebilir"}
        >
          <Toggle
            value={isPrivate}
            onChange={v => { setIsPrivate(v); savePreferences({ isPrivate: v }) }}
          />
        </SettingRow>
      </Section>

      {/* Uygulama hakkında */}
      <Section title="Uygulama">
        <SettingRow
          icon={<Info size={18} />}
          label="Vibe Hakkında"
          sublabel="Duyguyla çiz, paylaş — v1.0"
        />
        <SettingRow
          icon={<User size={18} />}
          label="Profilini Görüntüle"
          onClick={() => router.push(`/profile/${user?.uid}`)}
        />
      </Section>

      {/* Çıkış & Tehlike */}
      <Section title="Oturum">
        <SettingRow
          icon={<LogOut size={18} />}
          label="Çıkış Yap"
          onClick={handleLogout}
        />
        <SettingRow
          icon={<Trash2 size={18} />}
          label="Hesabı Sil"
          sublabel="Tüm veriler kalıcı olarak silinir"
          onClick={() => setModal("delete")}
          danger
        />
      </Section>

      {/* ─── Modals ─── */}

      {modal === "password" && (
        <Modal title="Şifre Değiştir" onClose={() => setModal(null)}>
          <PasswordInput label="Mevcut Şifre" value={curPass} onChange={setCurPass} show={showPass} onToggleShow={() => setShowPass(s => !s)} />
          <PasswordInput label="Yeni Şifre" value={newPass} onChange={setNewPass} show={showPass} onToggleShow={() => setShowPass(s => !s)} />
          <PasswordInput label="Yeni Şifre (Tekrar)" value={confirmPass} onChange={setConfirmPass} show={showPass} onToggleShow={() => setShowPass(s => !s)} />
          <div className="flex gap-2 pt-1">
            <button onClick={() => setModal(null)} className="flex-1 py-2.5 rounded-[12px] text-sm font-semibold text-ink-muted bg-surface-muted">
              İptal
            </button>
            <button onClick={handleChangePassword} disabled={passLoading} className="flex-1 py-2.5 rounded-[12px] text-sm font-semibold text-white bg-accent disabled:opacity-60 flex items-center justify-center gap-1.5">
              {passLoading ? "Kaydediliyor…" : <><Check size={14} /> Kaydet</>}
            </button>
          </div>
        </Modal>
      )}

      {modal === "email" && (
        <Modal title="E-posta Değiştir" onClose={() => setModal(null)}>
          <div>
            <label className="block text-xs font-medium text-ink-muted mb-1.5">Yeni E-posta</label>
            <input
              type="email" value={newEmail} onChange={e => setNewEmail(e.target.value)}
              className="w-full px-4 py-2.5 rounded-[12px] bg-canvas border border-rim text-sm text-ink focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent transition"
            />
          </div>
          <PasswordInput label="Mevcut Şifre (Doğrulama)" value={emailPass} onChange={setEmailPass} show={showEPass} onToggleShow={() => setShowEPass(s => !s)} />
          <div className="flex gap-2 pt-1">
            <button onClick={() => setModal(null)} className="flex-1 py-2.5 rounded-[12px] text-sm font-semibold text-ink-muted bg-surface-muted">
              İptal
            </button>
            <button onClick={handleChangeEmail} disabled={emailLoading} className="flex-1 py-2.5 rounded-[12px] text-sm font-semibold text-white bg-accent disabled:opacity-60 flex items-center justify-center gap-1.5">
              {emailLoading ? "Güncelleniyor…" : <><Check size={14} /> Güncelle</>}
            </button>
          </div>
        </Modal>
      )}

      {modal === "delete" && (
        <Modal title="Hesabı Sil" onClose={() => setModal(null)}>
          <div className="bg-red-50 border border-red-200 rounded-[12px] p-3 flex gap-2.5">
            <AlertTriangle size={16} className="text-red-400 shrink-0 mt-0.5" />
            <p className="text-xs text-red-600 leading-relaxed">
              Bu işlem geri alınamaz. Tüm çizimler, beğeniler ve takip verileri kalıcı olarak silinir.
            </p>
          </div>
          <PasswordInput label="Şifren" value={deletePass} onChange={setDeletePass} show={showDeletePass} onToggleShow={() => setShowDeletePass(s => !s)} />
          <div>
            <label className="block text-xs font-medium text-ink-muted mb-1.5">
              Onaylamak için <span className="font-bold text-red-500">SİL</span> yaz
            </label>
            <input
              type="text" value={deleteConfirm} onChange={e => setDeleteConfirm(e.target.value)}
              placeholder="SİL"
              className="w-full px-4 py-2.5 rounded-[12px] bg-canvas border border-red-200 text-sm text-ink focus:outline-none focus:ring-2 focus:ring-red-200 focus:border-red-400 transition"
            />
          </div>
          <div className="flex gap-2 pt-1">
            <button onClick={() => setModal(null)} className="flex-1 py-2.5 rounded-[12px] text-sm font-semibold text-ink-muted bg-surface-muted">
              Vazgeç
            </button>
            <button
              onClick={handleDeleteAccount}
              disabled={deleteLoading || deleteConfirm !== "SİL"}
              className="flex-1 py-2.5 rounded-[12px] text-sm font-semibold text-white bg-red-500 disabled:opacity-50 flex items-center justify-center gap-1.5"
            >
              {deleteLoading ? "Siliniyor…" : <><Trash2 size={14} /> Hesabı Sil</>}
            </button>
          </div>
        </Modal>
      )}
    </div>
  )
}
