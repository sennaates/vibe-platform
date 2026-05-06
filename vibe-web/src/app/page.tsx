"use client"

import { Feed } from "@/components/feed/Feed"
import { useAuth } from "@/hooks/useAuth"
import Link from "next/link"
import Image from "next/image"

export default function HomePage() {
  const { user, profile, loading } = useAuth()

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
                    Vibe — kalp atışın ve duygularınla şekillenen çizim deneyimi. Hissettiklerini çizime dönüştür.
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

      {/* Feed */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8">
        <Feed />
      </div>
    </main>
  )
}
