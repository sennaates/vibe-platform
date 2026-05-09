"use client"

import { useEffect, useState } from "react"
import { CheckCircle2, XCircle, Info, X } from "lucide-react"
import { toast } from "@/lib/toast"

interface ToastMsg { id: number; msg: string; type: "success" | "error" | "info" }

const ICONS = {
  success: <CheckCircle2 size={16} className="text-emerald-500 shrink-0" />,
  error:   <XCircle     size={16} className="text-red-500 shrink-0" />,
  info:    <Info        size={16} className="text-blue-500 shrink-0" />,
}

export function ToastContainer() {
  const [toasts, setToasts] = useState<ToastMsg[]>([])

  useEffect(() => {
    let counter = 0
    toast._subscribe((msg, type) => {
      const id = ++counter
      setToasts(prev => [...prev, { id, msg, type }])
      setTimeout(() => setToasts(prev => prev.filter(t => t.id !== id)), 3000)
    })
    return () => toast._unsubscribe()
  }, [])

  if (toasts.length === 0) return null

  return (
    <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-[9999] flex flex-col gap-2 items-center pointer-events-none">
      {toasts.map(t => (
        <div
          key={t.id}
          className="flex items-center gap-2.5 px-4 py-2.5 bg-[#1C1917] text-white rounded-full shadow-xl text-sm font-medium animate-in fade-in slide-in-from-bottom-3 duration-200 pointer-events-auto"
        >
          {ICONS[t.type]}
          {t.msg}
          <button
            onClick={() => setToasts(prev => prev.filter(x => x.id !== t.id))}
            className="ml-1 text-white/60 hover:text-white transition-colors"
          >
            <X size={13} />
          </button>
        </div>
      ))}
    </div>
  )
}
