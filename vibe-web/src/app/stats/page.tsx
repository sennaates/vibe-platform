"use client"

import { useEffect, useState } from "react"
import Link from "next/link"
import { collection, query, where, orderBy, getDocs } from "firebase/firestore"
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer,
  LineChart, Line, CartesianGrid, Area, AreaChart,
} from "recharts"
import { db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import type { Post } from "@/types"

interface EmotionStat { label: string; emoji: string; count: number; color: string }

const EMOTION_COLORS: Record<string, string> = {
  "Sakin": "#4A7FA5", "Mutlu": "#D9A23F", "Enerjik": "#D9723F",
  "Heyecanlı": "#C0504A", "Kaygılı": "#7C5CBF", "Stresli": "#8B3A3A",
  "Üzgün": "#556B8B", "Yorgun": "#6B7280", "Huzurlu": "#C45F8A",
  "Odaklanmış": "#3A8FA0",
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
        <div className="h-8 w-40 bg-[#E8E4DC] rounded-full" />
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => <div key={i} className="h-28 bg-[#E8E4DC] rounded-[18px]" />)}
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          <div className="h-64 bg-[#E8E4DC] rounded-[18px]" />
          <div className="h-64 bg-[#E8E4DC] rounded-[18px]" />
        </div>
      </div>
    )
  }

  if (!user) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[calc(100vh-56px)] gap-4 px-4">
        <span className="text-6xl block">📊</span>
        <p className="text-xl font-bold text-[#1C1917]">İstatistikleri görmek için giriş yap</p>
        <Link href="/auth" className="mt-3 px-6 py-3 bg-[#D9723F] text-white rounded-[14px] text-sm font-semibold shadow-sm hover:bg-[#C4622F] transition-colors">
          Giriş Yap
        </Link>
      </div>
    )
  }

  const emotionMap: Record<string, EmotionStat> = {}
  posts.forEach(p => {
    const label = p.emotion.split(" ")[0]
    if (!emotionMap[label]) emotionMap[label] = { label, emoji: p.emotion.split(" ")[1] ?? "🎨", count: 0, color: EMOTION_COLORS[label] ?? "#D9723F" }
    emotionMap[label].count++
  })
  const emotionData = Object.values(emotionMap).sort((a, b) => b.count - a.count)

  const bpmData = [...posts].reverse().slice(-30).map((p, i) => ({ index: i + 1, bpm: p.bpm, emotion: p.emotion.split(" ")[0] }))
  const avgBpm = posts.length ? Math.round(posts.reduce((s, p) => s + p.bpm, 0) / posts.length) : 0
  const maxBpm = posts.length ? Math.max(...posts.map(p => p.bpm)) : 0
  const minBpm = posts.length ? Math.min(...posts.map(p => p.bpm)) : 0
  const dominant = emotionData[0]

  const tooltipStyle = { fontSize: 12, borderRadius: 12, border: "1px solid #E8E4DC", boxShadow: "0 4px 12px rgba(0,0,0,0.06)" }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8 space-y-6">
      <div>
        <p className="text-xs font-semibold text-[#A8A29E] uppercase tracking-widest mb-0.5">Özet</p>
        <h1 className="text-2xl sm:text-3xl font-bold text-[#1C1917]">İstatistikler</h1>
        <p className="text-sm text-[#78716C] mt-1">Duygu ve ritim geçmişin</p>
      </div>

      {posts.length === 0 ? (
        <div className="flex flex-col items-center py-24 text-center gap-3">
          <span className="text-6xl block">📊</span>
          <p className="font-bold text-[#1C1917] text-xl">Henüz veri yok</p>
          <p className="text-sm text-[#78716C]">Çizim yaptıkça istatistikler burada görünür</p>
          <Link href="/canvas" className="mt-4 px-6 py-3 bg-[#D9723F] text-white rounded-[14px] text-sm font-semibold shadow-sm">
            Çizmeye Başla
          </Link>
        </div>
      ) : (
        <>
          {/* Stat cards — 4 columns on desktop */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
            <StatCard icon="🎨" label="Toplam Çizim" value={posts.length.toString()} accent="#D9723F" />
            <StatCard icon="💡" label="Dominant Duygu" value={dominant ? `${dominant.emoji} ${dominant.label}` : "—"} accent={dominant?.color ?? "#D9723F"} />
            <StatCard icon="💓" label="Ortalama BPM" value={avgBpm.toString()} accent="#C45F8A" />
            <StatCard icon="⚡" label="BPM Aralığı" value={`${minBpm}–${maxBpm}`} accent="#D9723F" />
          </div>

          {/* Charts — side by side on desktop */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
            {bpmData.length > 1 && (
              <div className="bg-white border border-[#E8E4DC] rounded-[22px] p-5 sm:p-6 shadow-sm">
                <p className="text-xs font-semibold text-[#A8A29E] uppercase tracking-widest mb-0.5">Zaman Serisi</p>
                <p className="text-base font-semibold text-[#1C1917] mb-5">BPM Geçmişi</p>
                <ResponsiveContainer width="100%" height={220}>
                  <AreaChart data={bpmData} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
                    <defs>
                      <linearGradient id="bpmGrad" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="#D9723F" stopOpacity={0.25} />
                        <stop offset="100%" stopColor="#D9723F" stopOpacity={0.02} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="0" stroke="#F5F3EF" vertical={false} />
                    <XAxis dataKey="index" tick={{ fontSize: 10, fill: "#A8A29E" }} axisLine={false} tickLine={false} />
                    <YAxis tick={{ fontSize: 10, fill: "#A8A29E" }} domain={[40, 180]} axisLine={false} tickLine={false} />
                    <Tooltip contentStyle={tooltipStyle} formatter={(v) => [`${v} BPM`, ""]} cursor={{ stroke: "#E8E4DC" }} />
                    <Area type="monotone" dataKey="bpm" stroke="#D9723F" strokeWidth={2} fill="url(#bpmGrad)" dot={{ fill: "#D9723F", r: 3, strokeWidth: 0 }} activeDot={{ r: 5, fill: "#D9723F", strokeWidth: 2, stroke: "#fff" }} />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            )}

            {emotionData.length > 0 && (
              <div className="bg-white border border-[#E8E4DC] rounded-[22px] p-5 sm:p-6 shadow-sm">
                <p className="text-xs font-semibold text-[#A8A29E] uppercase tracking-widest mb-0.5">Dağılım</p>
                <p className="text-base font-semibold text-[#1C1917] mb-5">Duygu Dağılımı</p>
                <ResponsiveContainer width="100%" height={220}>
                  <BarChart data={emotionData} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="0" stroke="#F5F3EF" vertical={false} />
                    <XAxis dataKey="emoji" tick={{ fontSize: 16 }} axisLine={false} tickLine={false} />
                    <YAxis tick={{ fontSize: 10, fill: "#A8A29E" }} allowDecimals={false} axisLine={false} tickLine={false} />
                    <Tooltip contentStyle={tooltipStyle} formatter={(v, _, props) => [`${v} çizim`, (props as { payload?: EmotionStat }).payload?.label ?? ""]} cursor={{ fill: "#F5F3EF" }} />
                    <Bar dataKey="count" radius={[8, 8, 0, 0]} fill="#D9723F" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}
          </div>
        </>
      )}
    </div>
  )
}

function StatCard({ icon, label, value, accent }: { icon: string; label: string; value: string; accent: string }) {
  return (
    <div className="bg-white border border-[#E8E4DC] rounded-[18px] p-4 sm:p-5 shadow-sm">
      <div className="flex items-center gap-2.5 mb-2">
        <div className="w-8 h-8 rounded-[10px] flex items-center justify-center text-sm" style={{ backgroundColor: accent + "15" }}>
          {icon}
        </div>
        <span className="text-xs font-medium text-[#78716C]">{label}</span>
      </div>
      <p className="text-xl sm:text-2xl font-bold text-[#1C1917]">{value}</p>
    </div>
  )
}
