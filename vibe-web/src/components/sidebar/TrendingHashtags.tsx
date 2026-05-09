"use client"

import { useEffect, useState } from "react"
import Link from "next/link"
import { collection, query, orderBy, limit, getDocs } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { Hash } from "lucide-react"

interface TagTrend {
  tag: string
  count: number
}

export function TrendingHashtags() {
  const [trends, setTrends] = useState<TagTrend[]>([])

  useEffect(() => {
    async function load() {
      const snap = await getDocs(
        query(collection(db, "posts"), orderBy("createdAt", "desc"), limit(200))
      )
      const map: Record<string, number> = {}
      snap.docs.forEach(d => {
        const tags = d.data().tags as string[] | undefined
        if (!tags) return
        tags.forEach(t => { map[t] = (map[t] ?? 0) + 1 })
      })
      const sorted = Object.entries(map)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 8)
        .map(([tag, count]) => ({ tag, count }))
      setTrends(sorted)
    }
    load()
  }, [])

  if (trends.length === 0) return null

  return (
    <div className="bg-surface border border-rim rounded-[22px] p-5 shadow-sm">
      <div className="flex items-center gap-2 mb-4">
        <Hash size={15} className="text-accent" />
        <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest">Trend Hashtagler</p>
      </div>
      <div className="flex flex-wrap gap-2">
        {trends.map(({ tag, count }) => (
          <Link
            key={tag}
            href={`/hashtag/${tag}`}
            className="inline-flex items-center gap-1 px-3 py-1.5 rounded-full text-xs font-semibold bg-accent/10 text-accent hover:bg-accent/20 transition-colors"
          >
            <span>#</span>
            <span>{tag}</span>
            <span className="ml-0.5 text-[10px] text-accent/60 font-medium">{count}</span>
          </Link>
        ))}
      </div>
    </div>
  )
}
