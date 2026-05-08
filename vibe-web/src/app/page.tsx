"use client"

import { useState } from "react"
import Link from "next/link"
import Image from "next/image"
import { Feed } from "@/components/feed/Feed"
import { FollowingFeed } from "@/components/feed/FollowingFeed"
import { useAuth } from "@/hooks/useAuth"
import { Compass, Users } from "lucide-react"
import { cn } from "@/lib/utils"

type Tab = "discover" | "following"

export default function HomePage() {
  const { user, profile, loading } = useAuth()
  const [tab, setTab] = useState<Tab>("discover")

  return (
    <main className="w-full">
      {/* Hero / Welcome */}
      {!loading && (
        <div className="border-b border-[#E8E4DC] bg-white/50">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8">
            {user && profile ? (
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs font-semibold text-[#A8A29E] uppercase tracking-widest mb-1">Hoş geldin</p>
                  <h1 className="text-2xl sm:text-3xl font-bold text-[#1C1917]">
                    İyi günler, {profile.displayName.split(" ")[0]} {profile.avatarEmoji}
                  </h1>
                </div>
                <Link
                  href="/canvas"
                  className="px-5 py-2.5 bg-[#D9723F] text-white rounded-[14px] text-sm font-semibold shadow-sm hover:bg-[#C4622F] transition-all active:scale-95"
                >
                  + Yeni Çizim
                </Link>
              </div>
            ) : !user ? (
              <div className="flex flex-col sm:flex-row items-center gap-6 sm:gap-8">
                <div className="w-16 h-16 sm:w-20 sm:h-20 rounded-2xl overflow-hidden shadow-md shrink-0">
                  <Image src="/logo.png" alt="Vibe" width={80} height={80} />
                </div>
                <div className="text-center sm:text-left flex-1">
                  <h1 className="text-2xl sm:text-3xl font-bold text-[#1C1917]">Duygularınla çiz, paylaş</h1>
                  <p className="text-sm sm:text-base text-[#78716C] mt-1.5 max-w-lg">
                    Vibe — kalp atışın ve duygularınla şekillenen çizim deneyimi.
                  </p>
                </div>
                <Link
                  href="/auth"
                  className="px-6 py-3 bg-[#D9723F] text-white rounded-[14px] text-sm font-semibold shadow-sm hover:bg-[#C4622F] transition-all shrink-0"
                >
                  Hemen Başla
                </Link>
              </div>
            ) : null}
          </div>
        </div>
      )}

      {/* Feed area */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8">
        {/* Tab switcher */}
        <div className="flex items-center gap-1 mb-6 bg-white border border-[#E8E4DC] rounded-[16px] p-1 w-fit shadow-sm">
          <TabBtn
            active={tab === "discover"}
            onClick={() => setTab("discover")}
          >
            <Compass size={15} />
            Keşfet
          </TabBtn>
          <TabBtn
            active={tab === "following"}
            onClick={() => setTab("following")}
          >
            <Users size={15} />
            Takip
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
        "flex items-center gap-1.5 px-4 py-2 rounded-[12px] text-sm font-semibold transition-all duration-150",
        active
          ? "bg-[#D9723F] text-white shadow-sm"
          : "text-[#78716C] hover:bg-[#F5F3EF] hover:text-[#1C1917]"
      )}
    >
      {children}
    </button>
  )
}
