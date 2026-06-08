"use client"

import Link from "next/link"
import Image from "next/image"
import { usePathname } from "next/navigation"
import { Home, ImageIcon, BarChart2, PenLine, Search, Bell, Settings, Sun, Moon } from "lucide-react"
import { useEffect, useState } from "react"
import { useTheme } from "next-themes"
import { collection, query, where, onSnapshot } from "firebase/firestore"
import { db } from "@/lib/firebase"
import { useAuth } from "@/hooks/useAuth"
import { Avatar } from "@/components/ui/Avatar"
import { cn } from "@/lib/utils"

export function Navbar() {
  const { user, profile } = useAuth()
  const pathname = usePathname()
  const [unread, setUnread] = useState(0)
  const { resolvedTheme, setTheme } = useTheme()
  const [mounted, setMounted] = useState(false)
  useEffect(() => {
    const timer = setTimeout(() => setMounted(true), 0)
    return () => clearTimeout(timer)
  }, [])

  // Subscribe to unread notification count
  useEffect(() => {
    if (!user) {
      const timer = setTimeout(() => setUnread(0), 0)
      return () => clearTimeout(timer)
    }
    const q = query(
      collection(db, "notifications", user.uid, "items"),
      where("read", "==", false)
    )
    const unsub = onSnapshot(q, snap => setUnread(snap.size))
    return unsub
  }, [user])

  return (
    <header className="sticky top-0 z-50 bg-canvas/90 backdrop-blur-md border-b border-rim">
      <div className="w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-14 flex items-center justify-between">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-2.5 group relative">
          {/* Logo container with pulse & glow */}
          <div className="relative w-8.5 h-8.5 rounded-[10px] overflow-hidden border border-rim/60 shadow-sm transition-all duration-300 group-hover:border-accent/30 group-hover:shadow-md group-hover:shadow-accent/10 shrink-0">
            {/* Ambient rotating light behind logo (visible on hover) */}
            <div className="absolute inset-0 bg-gradient-to-tr from-accent via-orange-500 to-pink-500 opacity-0 group-hover:opacity-15 transition-opacity duration-300" />
            <div className="w-full h-full relative transition-transform duration-300 group-hover:scale-105 group-hover:animate-heartbeat">
              <Image src="/logo.png" alt="Vibe" fill className="object-cover" />
            </div>
          </div>
          <div className="flex flex-col text-left">
            <span className="font-black text-transparent bg-clip-text bg-gradient-to-r from-accent via-orange-500 to-pink-500 text-lg leading-none tracking-tight group-hover:brightness-105 transition-all duration-300">
              Vibe
            </span>
            <span className="text-[8px] font-bold text-ink-subtle uppercase tracking-widest leading-none mt-0.5 group-hover:text-accent transition-colors">
              Duygu & Ritim
            </span>
          </div>
        </Link>

        {/* Center nav — hidden on mobile, shown on lg+ */}
        <nav className="hidden lg:flex items-center gap-1 bg-surface/60 backdrop-blur rounded-full border border-rim/60 px-1.5 py-1">
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
                <span className="absolute top-0.5 right-0.5 min-w-[16px] h-4 px-0.5 bg-accent text-white text-[9px] font-bold rounded-full flex items-center justify-center pointer-events-none">
                  {unread > 9 ? "9+" : unread}
                </span>
              )}
            </div>
          )}

          {/* Dark mode toggle */}
          {mounted && (
            <button
              onClick={() => setTheme(resolvedTheme === "dark" ? "light" : "dark")}
              className="p-2 rounded-[10px] transition-all duration-150 text-ink-subtle hover:bg-surface-muted hover:text-ink-muted"
              aria-label="Tema değiştir"
            >
              {resolvedTheme === "dark"
                ? <Sun size={18} strokeWidth={1.75} />
                : <Moon size={18} strokeWidth={1.75} />
              }
            </button>
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
                  ? "ring-2 ring-accent ring-offset-1"
                  : "hover:ring-2 hover:ring-rim hover:ring-offset-1"
              )}
            >
              <Avatar emoji={profile.avatarEmoji} color={profile.profileColor} size="sm" />
            </Link>
          ) : !user ? (
            <Link
              href="/auth"
              className="ml-1 px-4 py-1.5 bg-accent text-white text-sm font-semibold rounded-full hover:bg-accent-hover transition-colors"
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
          ? "bg-accent/12 text-accent"
          : "text-ink-muted hover:bg-surface-muted hover:text-ink"
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
          ? "bg-accent/12 text-accent"
          : "text-ink-subtle hover:bg-surface-muted hover:text-ink-muted"
      )}
    >
      {children}
    </Link>
  )
}
