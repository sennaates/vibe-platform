"use client"

import Link from "next/link"
import Image from "next/image"
import { usePathname } from "next/navigation"
import { Home, ImageIcon, BarChart2, PenLine, Search, Bell, Settings } from "lucide-react"
import { useEffect, useState } from "react"
import { collection, query, where, onSnapshot } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { Avatar } from "@/components/ui/Avatar"
import { cn } from "@/lib/utils"

export function Navbar() {
  const { user, profile } = useAuth()
  const pathname = usePathname()
  const [unread, setUnread] = useState(0)

  // Subscribe to unread notification count
  useEffect(() => {
    if (!user) { setUnread(0); return }
    const q = query(
      collection(db, "notifications", user.uid, "items"),
      where("read", "==", false)
    )
    const unsub = onSnapshot(q, snap => setUnread(snap.size))
    return unsub
  }, [user])

  return (
    <header className="sticky top-0 z-50 bg-[#FAF8F4]/90 backdrop-blur-md border-b border-[#E8E4DC]">
      <div className="w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-14 flex items-center justify-between">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-2.5 group">
          <div className="w-8 h-8 rounded-lg overflow-hidden shadow-sm group-hover:shadow transition-shadow">
            <Image src="/logo.png" alt="Vibe" width={32} height={32} />
          </div>
          <span className="font-bold text-[#1C1917] text-base tracking-tight">Vibe</span>
        </Link>

        {/* Center nav — hidden on mobile, shown on lg+ */}
        <nav className="hidden lg:flex items-center gap-1 bg-white/60 backdrop-blur rounded-full border border-[#E8E4DC]/60 px-1.5 py-1">
          <NavLink href="/" active={pathname === "/"} label="Akış">
            <Home size={17} strokeWidth={pathname === "/" ? 2.5 : 1.75} />
            <span className="text-[13px]">Akış</span>
          </NavLink>
          {user && (
            <>
              <NavLink href="/canvas" active={pathname === "/canvas"} label="Çiz">
                <PenLine size={17} strokeWidth={pathname === "/canvas" ? 2.5 : 1.75} />
                <span className="text-[13px]">Çiz</span>
              </NavLink>
              <NavLink href="/gallery" active={pathname === "/gallery"} label="Galeri">
                <ImageIcon size={17} strokeWidth={pathname === "/gallery" ? 2.5 : 1.75} />
                <span className="text-[13px]">Galeri</span>
              </NavLink>
              <NavLink href="/stats" active={pathname === "/stats"} label="Stats">
                <BarChart2 size={17} strokeWidth={pathname === "/stats" ? 2.5 : 1.75} />
                <span className="text-[13px]">İstatistik</span>
              </NavLink>
            </>
          )}
        </nav>

        {/* Right side */}
        <div className="flex items-center gap-1">
          {/* Mobile nav icons */}
          <nav className="flex lg:hidden items-center gap-0.5">
            <NavIconLink href="/" active={pathname === "/"}>
              <Home size={18} strokeWidth={pathname === "/" ? 2.5 : 1.75} />
            </NavIconLink>
            {user && (
              <>
                <NavIconLink href="/canvas" active={pathname === "/canvas"}>
                  <PenLine size={18} strokeWidth={pathname === "/canvas" ? 2.5 : 1.75} />
                </NavIconLink>
                <NavIconLink href="/gallery" active={pathname === "/gallery"}>
                  <ImageIcon size={18} strokeWidth={pathname === "/gallery" ? 2.5 : 1.75} />
                </NavIconLink>
                <NavIconLink href="/stats" active={pathname === "/stats"}>
                  <BarChart2 size={18} strokeWidth={pathname === "/stats" ? 2.5 : 1.75} />
                </NavIconLink>
              </>
            )}
          </nav>

          {/* Search */}
          <NavIconLink href="/search" active={pathname === "/search"}>
            <Search size={18} strokeWidth={pathname === "/search" ? 2.5 : 1.75} />
          </NavIconLink>

          {/* Notifications bell */}
          {user && (
            <div className="relative">
              <NavIconLink href="/notifications" active={pathname === "/notifications"}>
                <Bell size={18} strokeWidth={pathname === "/notifications" ? 2.5 : 1.75} />
              </NavIconLink>
              {unread > 0 && (
                <span className="absolute top-0.5 right-0.5 min-w-[16px] h-4 px-0.5 bg-[#D9723F] text-white text-[9px] font-bold rounded-full flex items-center justify-center pointer-events-none">
                  {unread > 9 ? "9+" : unread}
                </span>
              )}
            </div>
          )}

          {/* Settings */}
          {user && (
            <NavIconLink href="/settings" active={pathname === "/settings"}>
              <Settings size={18} strokeWidth={pathname === "/settings" ? 2.5 : 1.75} />
            </NavIconLink>
          )}

          {/* Profile avatar or login */}
          {user && profile ? (
            <Link
              href={`/profile/${user.uid}`}
              className={cn(
                "ml-1 p-1 rounded-full transition-all",
                pathname.startsWith("/profile")
                  ? "ring-2 ring-[#D9723F] ring-offset-1"
                  : "hover:ring-2 hover:ring-[#E8E4DC] hover:ring-offset-1"
              )}
            >
              <Avatar emoji={profile.avatarEmoji} color={profile.profileColor} size="sm" />
            </Link>
          ) : !user ? (
            <Link
              href="/auth"
              className="ml-1 px-4 py-1.5 bg-[#D9723F] text-white text-sm font-semibold rounded-full hover:bg-[#C4622F] transition-colors"
            >
              Giriş
            </Link>
          ) : null}
        </div>
      </div>
    </header>
  )
}

function NavLink({
  href, active, children, label,
}: {
  href: string; active: boolean; children: React.ReactNode; label: string
}) {
  return (
    <Link
      href={href}
      title={label}
      className={cn(
        "flex items-center gap-1.5 px-3 py-1.5 rounded-full transition-all duration-150 font-medium",
        active
          ? "bg-[#D9723F]/12 text-[#D9723F]"
          : "text-[#78716C] hover:bg-[#F5F3EF] hover:text-[#1C1917]"
      )}
    >
      {children}
    </Link>
  )
}

function NavIconLink({
  href, active, children,
}: {
  href: string; active: boolean; children: React.ReactNode
}) {
  return (
    <Link
      href={href}
      className={cn(
        "p-2 rounded-[10px] transition-all duration-150",
        active
          ? "bg-[#D9723F]/12 text-[#D9723F]"
          : "text-[#A8A29E] hover:bg-[#F5F3EF] hover:text-[#78716C]"
      )}
    >
      {children}
    </Link>
  )
}
