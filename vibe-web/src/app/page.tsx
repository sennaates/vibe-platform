"use client"

import { useState } from "react"
import Link from "next/link"
import { Feed } from "@/components/feed/Feed"
import { FollowingFeed } from "@/components/feed/FollowingFeed"
import { useAuth } from "@/hooks/useAuth"
import { LandingPage } from "@/components/layout/LandingPage"
import { Compass, Users } from "lucide-react"
import { cn } from "@/lib/utils"

type Tab = "discover" | "following"

export default function HomePage() {
  const { user, profile, loading } = useAuth()
  const [tab, setTab] = useState<Tab>("discover")

  if (loading) {
    return (
      <div className="min-h-[calc(100vh-56px)] flex items-center justify-center bg-canvas">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent"></div>
      </div>
    )
  }

  if (!user) {
    return <LandingPage />
  }

  return (
    <main className="w-full">
      {/* Hero / Welcome */}
      <div className="border-b border-rim bg-surface/50">
        <div className="max-w-2xl mx-auto px-4 sm:px-6 py-6 sm:py-8">
          {profile ? (
            <div className="flex items-center justify-between">
              <div>
                <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest mb-1">Hoş geldin</p>
                <h1 className="text-2xl sm:text-3xl font-bold text-ink">
                  İyi günler, {profile.displayName.split(" ")[0]} {profile.avatarEmoji}
                </h1>
              </div>
              <Link
                href="/canvas"
                className="px-5 py-2.5 bg-accent text-white rounded-[14px] text-sm font-semibold shadow-sm hover:bg-accent-hover transition-all active:scale-95"
              >
                + Yeni Çizim
              </Link>
            </div>
          ) : null}
        </div>
      </div>

      {/* Feed — tek ortalı sütun */}
      <div className="max-w-2xl mx-auto px-4 sm:px-6 py-5 sm:py-8">
        {/* Tab switcher */}
        <div className="flex items-center gap-1 mb-5 sm:mb-6 bg-surface border border-rim rounded-[16px] p-1 w-fit shadow-sm">
          <TabBtn active={tab === "discover"} onClick={() => setTab("discover")}>
            <Compass size={14} className="shrink-0" />
            <span>Keşfet</span>
          </TabBtn>
          <TabBtn active={tab === "following"} onClick={() => setTab("following")}>
            <Users size={14} className="shrink-0" />
            <span>Takip</span>
          </TabBtn>
        </div>

        {tab === "discover" ? <Feed /> : <FollowingFeed />}
      </div>
    </main>
  )
}

function TabBtn({
  active, onClick, children,
}: {
  active: boolean; onClick: () => void; children: React.ReactNode
}) {
  return (
    <button
      onClick={onClick}
      className={cn(
        "flex items-center gap-1.5 px-3 sm:px-4 py-2 rounded-[12px] text-xs sm:text-sm font-semibold transition-all duration-150 whitespace-nowrap",
        active
          ? "bg-accent text-white shadow-sm"
          : "text-ink-muted hover:bg-surface-muted hover:text-ink"
      )}
    >
      {children}
    </button>
  )
}
