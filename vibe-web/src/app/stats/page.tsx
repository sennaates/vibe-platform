"use client"

import { useEffect, useState } from "react"
import Link from "next/link"
import Image from "next/image"
import { collection, query, where, orderBy, getDocs } from "firebase/firestore"
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer,
  CartesianGrid, Area, AreaChart,
} from "recharts"
import { db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { Timestamp } from "firebase/firestore"
import type { Post } from "@/types"

interface EmotionStat { label: string; emoji: string; count: number; color: string }

const EMOTION_COLORS: Record<string, string> = {
  "Sakin": "#4A7FA5", "Mutlu": "#D9A23F", "Enerjik": "#D9723F",
  "Heyecanlı": "#C0504A", "Kaygılı": "#7C5CBF", "Stresli": "#8B3A3A",
  "Üzgün": "#556B8B", "Yorgun": "#6B7280", "Huzurlu": "#C45F8A",
  "Odaklanmış": "#3A8FA0",
}

function calcStreak(posts: Post[]): number {
  if (posts.length === 0) return 0
  const daySet = new Set(
    posts.map(p => {
      const d = (p.createdAt as Timestamp).toDate()
      d.setHours(0, 0, 0, 0)
      return d.getTime()
    })
  )
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  let streak = 0
  let check = today.getTime()
  while (daySet.has(check)) {
    streak++
    check -= 86_400_000
  }
  return streak
}

export default function StatsPage() {
  const { user, loading } = useAuth()
  const [posts, setPosts]       = useState<Post[]>([])
  const [fetching, setFetching] = useState(true)

  useEffect(() => {
    if (!user) { setFetching(false); return }
    const q = query(collection(db, "posts"), where("userId", "==", user.uid), orderBy("createdAt", "desc"))
    getDocs(q).then(snap => {
      setPosts(snap.docs.map(d => ({ id: d.id, ...d.data() } as Post)))
      setFetching(false)
    })
  }, [user])

  if (loading || fetching) {
    return (
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 animate-pulse space-y-5">
        <div className="h-8 w-40 bg-rim rounded-full" />
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-4">
          {[...Array(8)].map((_, i) => <div key={i} className="h-28 bg-rim rounded-[18px]" />)}
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <div className="h-64 bg-rim rounded-[18px]" />
          <div className="h-64 bg-rim rounded-[18px]" />
        </div>
      </div>
    )
  }

  if (!user) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[calc(100vh-56px)] gap-4 px-4">
        <span className="text-6xl block">📊</span>
        <p className="text-xl font-bold text-ink">İstatistikleri görmek için giriş yap</p>
        <Link href="/auth" className="mt-3 px-6 py-3 bg-accent text-white rounded-[14px] text-sm font-semibold shadow-sm hover:bg-accent-hover transition-colors">
          Giriş Yap
        </Link>
      </div>
    )
  }

  // Derived stats
  const emotionMap: Record<string, EmotionStat> = {}
  posts.forEach(p => {
    const label = p.emotion.split(" ")[0]
    if (!emotionMap[label]) emotionMap[label] = { label, emoji: p.emotion.split(" ")[1] ?? "🎨", count: 0, color: EMOTION_COLORS[label] ?? "#D9723F" }
    emotionMap[label].count++
  })
  const emotionData = Object.values(emotionMap).sort((a, b) => b.count - a.count)

  const bpmData = [...posts].reverse().slice(-30).map((p, i) => ({
    index: i + 1, bpm: p.bpm, emotion: p.emotion.split(" ")[0]
  }))

  const avgBpm    = posts.length ? Math.round(posts.reduce((s, p) => s + p.bpm, 0) / posts.length) : 0
  const maxBpm    = posts.length ? Math.max(...posts.map(p => p.bpm)) : 0
  const minBpm    = posts.length ? Math.min(...posts.map(p => p.bpm)) : 0
  const dominant  = emotionData[0]
  const totalLikes    = posts.reduce((s, p) => s + (p.likesCount ?? 0), 0)
  const totalComments = posts.reduce((s, p) => s + (p.commentsCount ?? 0), 0)
  const bestPost  = posts.length ? posts.reduce((a, b) => (b.likesCount ?? 0) > (a.likesCount ?? 0) ? b : a) : null
  const streak    = calcStreak(posts)

  // Haftanın günlerine göre dağılım
  const DAYS = ["Paz", "Pzt", "Sal", "Çar", "Per", "Cum", "Cmt"]
  const dayMap: Record<number, number> = { 0:0, 1:0, 2:0, 3:0, 4:0, 5:0, 6:0 }
  posts.forEach(p => {
    const d = (p.createdAt as Timestamp).toDate().getDay()
    dayMap[d]++
  })
  const dayData = DAYS.map((name, i) => ({ name, count: dayMap[i] }))

  // Top hashtagler (kendi gönderilerinden)
  const tagMap: Record<string, number> = {}
  posts.forEach(p => {
    if (p.tags) p.tags.forEach(t => { tagMap[t] = (tagMap[t] ?? 0) + 1 })
  })
  const topTags = Object.entries(tagMap).sort((a, b) => b[1] - a[1]).slice(0, 10)

  // Son 12 hafta aktivite haritası
  const today = new Date(); today.setHours(0,0,0,0)
  const heatCells: { date: string; count: number; level: number }[] = []
  const postDayMap: Record<string, number> = {}
  posts.forEach(p => {
    const d = (p.createdAt as Timestamp).toDate()
    d.setHours(0,0,0,0)
    const key = d.toISOString().slice(0,10)
    postDayMap[key] = (postDayMap[key] ?? 0) + 1
  })
  for (let i = 83; i >= 0; i--) {
    const d = new Date(today); d.setDate(d.getDate() - i)
    const key = d.toISOString().slice(0,10)
    const count = postDayMap[key] ?? 0
    heatCells.push({ date: key, count, level: count === 0 ? 0 : count === 1 ? 1 : count <= 2 ? 2 : 3 })
  }

  const tooltipStyle = {
    fontSize: 12, borderRadius: 12,
    border: "1px solid var(--rim)", backgroundColor: "var(--surface)",
    color: "var(--ink)", boxShadow: "0 4px 12px rgba(0,0,0,0.08)"
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8 space-y-6">
      <div>
        <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest mb-0.5">Özet</p>
        <h1 className="text-2xl sm:text-3xl font-bold text-ink">İstatistikler</h1>
        <p className="text-sm text-ink-muted mt-1">Duygu ve ritim geçmişin</p>
      </div>

      {posts.length === 0 ? (
        <div className="flex flex-col items-center py-24 text-center gap-3">
          <span className="text-6xl block">📊</span>
          <p className="font-bold text-ink text-xl">Henüz veri yok</p>
          <p className="text-sm text-ink-muted">Çizim yaptıkça istatistikler burada görünür</p>
          <Link href="/canvas" className="mt-4 px-6 py-3 bg-accent text-white rounded-[14px] text-sm font-semibold shadow-sm">
            Çizmeye Başla
          </Link>
        </div>
      ) : (
        <>
          {/* Row 1: activity stats */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-4">
            <StatCard icon="🎨" label="Toplam Çizim"   value={posts.length.toString()}                        accent="#D9723F" />
            <StatCard icon="❤️" label="Alınan Beğeni"  value={totalLikes.toString()}                          accent="#e53e3e" />
            <StatCard icon="💬" label="Alınan Yorum"   value={totalComments.toString()}                       accent="#6366f1" />
            <StatCard icon="🔥" label="Günlük Seri"    value={streak > 0 ? `${streak} gün` : "Bugün başla!"} accent="#f97316" highlight={streak >= 3} />
          </div>

          {/* Row 2: emotion & bpm stats */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 sm:gap-4">
            <StatCard icon="💡" label="Dominant Duygu"  value={dominant ? `${dominant.emoji} ${dominant.label}` : "—"} accent={dominant?.color ?? "#D9723F"} />
            <StatCard icon="💓" label="Ortalama BPM"   value={avgBpm.toString()}                              accent="#C45F8A" />
            <StatCard icon="⚡" label="BPM Aralığı"    value={`${minBpm}–${maxBpm}`}                          accent="#D9723F" />
            <StatCard icon="✨" label="Duygu Çeşidi"   value={`${emotionData.length} farklı`}                 accent="#D9A23F" />
          </div>

          {/* Best post */}
          {bestPost && bestPost.likesCount > 0 && (
            <div className="bg-surface border border-rim rounded-[22px] p-5 shadow-sm">
              <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest mb-3">En Çok Beğenilen</p>
              <Link href={`/post/${bestPost.id}`} className="flex items-center gap-4 group">
                <div className="w-16 h-16 rounded-[14px] overflow-hidden shrink-0 border border-rim">
                  {bestPost.imageUrl ? (
                    <Image src={bestPost.imageUrl} alt={bestPost.emotion} width={64} height={64} className="object-cover w-full h-full" />
                  ) : (
                    <div className="w-full h-full bg-surface-muted flex items-center justify-center text-2xl">🎨</div>
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-ink group-hover:underline truncate">{bestPost.emotion}</p>
                  <p className="text-sm text-ink-muted mt-0.5">
                    ❤️ {bestPost.likesCount} beğeni · 💬 {bestPost.commentsCount} yorum
                  </p>
                  {bestPost.caption && (
                    <p className="text-xs text-ink-subtle mt-0.5 truncate">{bestPost.caption}</p>
                  )}
                </div>
                <span className="text-2xl shrink-0">🏆</span>
              </Link>
            </div>
          )}

          {/* Aktivite Haritası */}
          <div className="bg-surface border border-rim rounded-[22px] p-5 sm:p-6 shadow-sm">
            <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest mb-0.5">Son 12 Hafta</p>
            <p className="text-base font-semibold text-ink mb-4">Aktivite Haritası</p>
            <div className="flex gap-1 flex-wrap">
              {heatCells.map(cell => (
                <div
                  key={cell.date}
                  title={`${cell.date}: ${cell.count} çizim`}
                  className="w-3.5 h-3.5 rounded-[3px] transition-colors"
                  style={{
                    backgroundColor:
                      cell.level === 0 ? "var(--surface-muted)" :
                      cell.level === 1 ? "#D9723F40" :
                      cell.level === 2 ? "#D9723F80" :
                                         "#D9723F"
                  }}
                />
              ))}
            </div>
            <div className="flex items-center gap-1.5 mt-3 justify-end">
              <span className="text-[10px] text-ink-subtle">Az</span>
              {[0,1,2,3].map(l => (
                <div key={l} className="w-3 h-3 rounded-[3px]" style={{
                  backgroundColor: l === 0 ? "var(--surface-muted)" : l === 1 ? "#D9723F40" : l === 2 ? "#D9723F80" : "#D9723F"
                }} />
              ))}
              <span className="text-[10px] text-ink-subtle">Çok</span>
            </div>
          </div>

          {/* Charts + Haftanın Günleri */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            {bpmData.length > 1 && (
              <div className="bg-surface border border-rim rounded-[22px] p-5 sm:p-6 shadow-sm">
                <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest mb-0.5">Zaman Serisi</p>
                <p className="text-base font-semibold text-ink mb-5">BPM Geçmişi</p>
                <ResponsiveContainer width="100%" height={200}>
                  <AreaChart data={bpmData} margin={{ top: 4, right: 4, left: -16, bottom: 0 }}>
                    <defs>
                      <linearGradient id="bpmGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="#D9723F" stopOpacity={0.25} />
                        <stop offset="100%" stopColor="#D9723F" stopOpacity={0.02} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="0" stroke="var(--rim)" vertical={false} />
                    <XAxis dataKey="index" tick={{ fontSize: 10, fill: "var(--ink-subtle)" }} axisLine={false} tickLine={false} />
                    <YAxis tick={{ fontSize: 10, fill: "var(--ink-subtle)" }} domain={[40, 180]} axisLine={false} tickLine={false} />
                    <Tooltip contentStyle={tooltipStyle} formatter={(v) => [`${v} BPM`, ""]} cursor={{ stroke: "var(--rim)" }} />
                    <Area type="monotone" dataKey="bpm" stroke="#D9723F" strokeWidth={2} fill="url(#bpmGrad)"
                      dot={{ fill: "#D9723F", r: 3, strokeWidth: 0 }}
                      activeDot={{ r: 5, fill: "#D9723F", strokeWidth: 2, stroke: "var(--surface)" }} />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            )}

            {emotionData.length > 0 && (
              <div className="bg-surface border border-rim rounded-[22px] p-5 sm:p-6 shadow-sm">
                <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest mb-0.5">Dağılım</p>
                <p className="text-base font-semibold text-ink mb-5">Duygu Dağılımı</p>
                <ResponsiveContainer width="100%" height={200}>
                  <BarChart data={emotionData} margin={{ top: 4, right: 4, left: -16, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="0" stroke="var(--rim)" vertical={false} />
                    <XAxis dataKey="emoji" tick={{ fontSize: 16 }} axisLine={false} tickLine={false} />
                    <YAxis tick={{ fontSize: 10, fill: "var(--ink-subtle)" }} allowDecimals={false} axisLine={false} tickLine={false} />
                    <Tooltip contentStyle={tooltipStyle}
                      formatter={(v, _, props) => [`${v} çizim`, (props as { payload?: EmotionStat }).payload?.label ?? ""]}
                      cursor={{ fill: "var(--surface-muted)" }} />
                    <Bar dataKey="count" radius={[8, 8, 0, 0]} fill="#D9723F" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}

            {/* Haftanın Günleri */}
            <div className="bg-surface border border-rim rounded-[22px] p-5 sm:p-6 shadow-sm">
              <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest mb-0.5">Alışkanlık</p>
              <p className="text-base font-semibold text-ink mb-5">Haftanın Günlerine Göre</p>
              <ResponsiveContainer width="100%" height={200}>
                <BarChart data={dayData} margin={{ top: 4, right: 4, left: -16, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="0" stroke="var(--rim)" vertical={false} />
                  <XAxis dataKey="name" tick={{ fontSize: 11, fill: "var(--ink-subtle)" }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 10, fill: "var(--ink-subtle)" }} allowDecimals={false} axisLine={false} tickLine={false} />
                  <Tooltip contentStyle={tooltipStyle} formatter={(v) => [`${v} çizim`, ""]} cursor={{ fill: "var(--surface-muted)" }} />
                  <Bar dataKey="count" radius={[8, 8, 0, 0]} fill="#C45F8A" />
                </BarChart>
              </ResponsiveContainer>
            </div>

            {/* Top Hashtagler */}
            {topTags.length > 0 && (
              <div className="bg-surface border border-rim rounded-[22px] p-5 sm:p-6 shadow-sm">
                <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest mb-0.5">Etiketler</p>
                <p className="text-base font-semibold text-ink mb-4">En Çok Kullandığın Hashtagler</p>
                <div className="space-y-2.5">
                  {topTags.map(([tag, count], i) => (
                    <Link key={tag} href={`/hashtag/${tag}`} className="flex items-center gap-3 group">
                      <span className="text-xs font-bold text-ink-subtle w-4 shrink-0">{i + 1}</span>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between mb-1">
                          <span className="text-sm font-semibold text-accent group-hover:underline">#{tag}</span>
                          <span className="text-xs text-ink-subtle">{count}×</span>
                        </div>
                        <div className="h-1.5 bg-surface-muted rounded-full overflow-hidden">
                          <div
                            className="h-full bg-accent rounded-full transition-all duration-500"
                            style={{ width: `${(count / (topTags[0]?.[1] ?? 1)) * 100}%`, opacity: 0.6 + (i === 0 ? 0.4 : 0) }}
                          />
                        </div>
                      </div>
                    </Link>
                  ))}
                </div>
              </div>
            )}
          </div>
        </>
      )}
    </div>
  )
}

function StatCard({
  icon, label, value, accent, highlight = false
}: {
  icon: string; label: string; value: string; accent: string; highlight?: boolean
}) {
  return (
    <div
      className="bg-surface border rounded-[18px] p-4 sm:p-5 shadow-sm transition-all"
      style={{ borderColor: highlight ? accent + "50" : "#E8E4DC" }}
    >
      <div className="flex items-center gap-2.5 mb-2">
        <div className="w-8 h-8 rounded-[10px] flex items-center justify-center text-sm" style={{ backgroundColor: accent + "18" }}>
          {icon}
        </div>
        <span className="text-xs font-medium text-ink-muted">{label}</span>
      </div>
      <p className="text-xl sm:text-2xl font-bold" style={{ color: highlight ? accent : "#1C1917" }}>{value}</p>
    </div>
  )
}
