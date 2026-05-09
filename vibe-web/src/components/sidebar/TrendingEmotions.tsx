"use client"

import { useEffect, useState } from "react"
import { collection, query, orderBy, limit, getDocs } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { TrendingUp } from "lucide-react"

interface EmotionTrend {
  label: string
  emoji: string
  count: number
  color: string
}

const EMOTION_COLORS: Record<string, string> = {
  "Sakin": "#4A7FA5", "Mutlu": "#D9A23F", "Enerjik": "#D9723F",
  "Heyecanlı": "#C0504A", "Kaygılı": "#7C5CBF", "Stresli": "#8B3A3A",
  "Üzgün": "#556B8B", "Yorgun": "#6B7280", "Huzurlu": "#C45F8A",
  "Odaklanmış": "#3A8FA0",
}

export function TrendingEmotions() {
  const [trends, setTrends] = useState<EmotionTrend[]>([])

  useEffect(() => {
    async function load() {
      const snap = await getDocs(
        query(collection(db, "posts"), orderBy("createdAt", "desc"), limit(100))
      )
      const map: Record<string, EmotionTrend> = {}
      snap.docs.forEach(d => {
        const parts = (d.data().emotion as string).split(" ")
        const label = parts[0]
        const emoji = parts[1] ?? "🎨"
        if (!map[label]) map[label] = { label, emoji, count: 0, color: EMOTION_COLORS[label] ?? "#D9723F" }
        map[label].count++
      })
      const sorted = Object.values(map).sort((a, b) => b.count - a.count).slice(0, 6)
      setTrends(sorted)
    }
    load()
  }, [])

  if (trends.length === 0) return null

  const max = trends[0]?.count ?? 1

  return (
    <div className="bg-white border border-[#E8E4DC] rounded-[22px] p-5 shadow-sm">
      <div className="flex items-center gap-2 mb-4">
        <TrendingUp size={15} className="text-[#D9723F]" />
        <p className="text-xs font-semibold text-[#A8A29E] uppercase tracking-widest">Trend Duygular</p>
      </div>
      <div className="space-y-3">
        {trends.map((t, i) => (
          <div key={t.label} className="flex items-center gap-2.5">
            <span className="text-base shrink-0 w-6 text-center">{t.emoji}</span>
            <div className="flex-1 min-w-0">
              <div className="flex items-center justify-between mb-0.5">
                <span className="text-xs font-semibold text-[#1C1917]">{t.label}</span>
                <span className="text-[10px] text-[#A8A29E] font-medium">{t.count}</span>
              </div>
              <div className="h-1.5 bg-[#F5F3EF] rounded-full overflow-hidden">
                <div
                  className="h-full rounded-full transition-all duration-500"
                  style={{
                    width: `${(t.count / max) * 100}%`,
                    backgroundColor: t.color,
                    opacity: i === 0 ? 1 : 0.6 + (1 - i / trends.length) * 0.4
                  }}
                />
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
