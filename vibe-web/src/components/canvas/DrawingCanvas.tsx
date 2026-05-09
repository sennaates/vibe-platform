"use client"

import { useRef, useEffect, useState, useCallback } from "react"
import { Undo2, Trash2, Download, Share2, Loader2, X } from "lucide-react"
import { getBrushParams, getStrokeWidth, type EmotionState } from "@/lib/drawingEngine"
import type { BgType } from "./EmotionPicker"

interface DrawingCanvasProps {
  emotion: EmotionState
  bpm: number
  bg: BgType
  onSave: (dataUrl: string, caption: string) => Promise<void>
  onDiscard: () => void
}

export function DrawingCanvas({ emotion, bpm, bg, onSave, onDiscard }: DrawingCanvasProps) {
  const canvasRef    = useRef<HTMLCanvasElement>(null)
  const overlayRef   = useRef<HTMLCanvasElement>(null)
  const isDrawing    = useRef(false)
  const lastPos      = useRef<{ x: number; y: number } | null>(null)
  const history      = useRef<ImageData[]>([])
  const colorIndex   = useRef(0)

  const [saving, setSaving]     = useState(false)
  const [caption, setCaption]   = useState("")
  const [showSave, setShowSave] = useState(false)

  const params = getBrushParams(emotion, bpm)

  // Canvas + overlay başlat
  useEffect(() => {
    const canvas = canvasRef.current
    const overlay = overlayRef.current
    if (!canvas || !overlay) return
    const ctx = canvas.getContext("2d")
    const octx = overlay.getContext("2d")
    if (!ctx || !octx) return

    const dpr = window.devicePixelRatio || 1
    const rect = canvas.getBoundingClientRect()

    canvas.width  = rect.width  * dpr
    canvas.height = rect.height * dpr
    ctx.scale(dpr, dpr)
    ctx.fillStyle = "#FAF8F4"
    ctx.fillRect(0, 0, rect.width, rect.height)
    ctx.fillStyle = "#C8C0B4"
    ctx.font = "13px system-ui"
    ctx.textAlign = "center"
    ctx.fillText("Çizmeye başla…", rect.width / 2, rect.height / 2)

    // Overlay — grid veya lined
    overlay.width  = rect.width  * dpr
    overlay.height = rect.height * dpr
    octx.scale(dpr, dpr)
    drawBackground(octx, rect.width, rect.height, bg)
  }, [bg])

  const getPos = (e: React.MouseEvent | React.TouchEvent) => {
    const canvas = canvasRef.current!
    const rect = canvas.getBoundingClientRect()
    if ("touches" in e) {
      const touch = e.touches[0]
      return { x: touch.clientX - rect.left, y: touch.clientY - rect.top }
    }
    return { x: (e as React.MouseEvent).clientX - rect.left, y: (e as React.MouseEvent).clientY - rect.top }
  }

  const saveHistory = useCallback(() => {
    const canvas = canvasRef.current
    const ctx = canvas?.getContext("2d")
    if (!canvas || !ctx) return
    const dpr = window.devicePixelRatio || 1
    history.current.push(ctx.getImageData(0, 0, canvas.width / dpr * dpr, canvas.height / dpr * dpr))
    if (history.current.length > 20) history.current.shift()
  }, [])

  const startDraw = useCallback((e: React.MouseEvent | React.TouchEvent) => {
    e.preventDefault()
    saveHistory()
    isDrawing.current = true
    lastPos.current = getPos(e)
    const ctx = canvasRef.current?.getContext("2d")
    if (!ctx || !lastPos.current) return
    ctx.beginPath()
    ctx.arc(lastPos.current.x, lastPos.current.y, params.minWidth / 2, 0, Math.PI * 2)
    const color = params.palette[colorIndex.current % params.palette.length]
    ctx.fillStyle = color + Math.round(params.opacity * 255).toString(16).padStart(2, "0")
    ctx.fill()
  }, [params, saveHistory])

  const draw = useCallback((e: React.MouseEvent | React.TouchEvent) => {
    e.preventDefault()
    if (!isDrawing.current || !lastPos.current) return
    const canvas = canvasRef.current
    const ctx = canvas?.getContext("2d")
    if (!canvas || !ctx) return
    const pos = getPos(e)
    const dx = pos.x - lastPos.current.x
    const dy = pos.y - lastPos.current.y
    const speed = Math.sqrt(dx * dx + dy * dy)
    if (speed > 15) colorIndex.current++
    const width = getStrokeWidth(params, dx, dy)
    const color = params.palette[colorIndex.current % params.palette.length]
    const alpha = Math.round(params.opacity * 255).toString(16).padStart(2, "0")
    ctx.save()
    if (params.blur > 0) ctx.filter = `blur(${params.blur}px)`
    ctx.strokeStyle = color + alpha
    ctx.lineWidth = width
    ctx.lineCap = "round"
    ctx.lineJoin = "round"
    if (params.strokeStyle === "sketchy") {
      ctx.beginPath()
      ctx.moveTo(lastPos.current.x + (Math.random() - 0.5) * 2, lastPos.current.y + (Math.random() - 0.5) * 2)
      ctx.lineTo(pos.x + (Math.random() - 0.5) * 2, pos.y + (Math.random() - 0.5) * 2)
      ctx.stroke()
    } else {
      ctx.beginPath()
      ctx.moveTo(lastPos.current.x, lastPos.current.y)
      ctx.lineTo(pos.x, pos.y)
      ctx.stroke()
    }
    ctx.restore()
    lastPos.current = pos
  }, [params])

  const endDraw = useCallback(() => {
    isDrawing.current = false
    lastPos.current = null
  }, [])

  const undo = () => {
    const canvas = canvasRef.current
    const ctx = canvas?.getContext("2d")
    if (!canvas || !ctx || history.current.length === 0) return
    ctx.putImageData(history.current.pop()!, 0, 0)
  }

  const clear = () => {
    const canvas = canvasRef.current
    const ctx = canvas?.getContext("2d")
    if (!canvas || !ctx) return
    saveHistory()
    const rect = canvas.getBoundingClientRect()
    ctx.fillStyle = "#FAF8F4"
    ctx.fillRect(0, 0, rect.width, rect.height)
  }

  const download = () => {
    const canvas = canvasRef.current
    if (!canvas) return
    const a = document.createElement("a")
    a.download = `vibe-${emotion.label}-${Date.now()}.png`
    a.href = canvas.toDataURL("image/png")
    a.click()
  }

  const handleSave = async () => {
    const canvas = canvasRef.current
    if (!canvas) return
    setSaving(true)
    await onSave(canvas.toDataURL("image/png"), caption)
    setSaving(false)
    setShowSave(false)
  }

  const bgLabel = bg === "grid" ? "🧮 Kareli" : bg === "lined" ? "📝 Çizgili" : "📄 Boş"

  return (
    <div className="flex flex-col h-[calc(100vh-56px)]">
      {/* Top bar */}
      <div className="flex items-center justify-between px-4 py-2 bg-surface border-b border-rim gap-3">
        <div className="flex items-center gap-2.5 min-w-0">
          <span className="text-xl shrink-0">{emotion.emoji}</span>
          <div className="min-w-0">
            <p className="text-sm font-semibold text-ink leading-tight truncate">{emotion.label}</p>
            <p className="text-xs text-ink-subtle">{bpm} BPM · {bgLabel}</p>
          </div>
        </div>
        <div className="flex items-center gap-1.5 shrink-0">
          <div className="flex items-center gap-0.5 bg-surface-muted rounded-[12px] p-1">
            <ToolButton onClick={undo} label="Geri Al"><Undo2 size={16} /></ToolButton>
            <ToolButton onClick={clear} label="Temizle"><Trash2 size={16} /></ToolButton>
            <ToolButton onClick={download} label="İndir"><Download size={16} /></ToolButton>
          </div>
          <button
            onClick={() => setShowSave(true)}
            className="px-3.5 py-1.5 rounded-[10px] text-sm font-semibold text-white transition-all active:scale-95 shadow-sm"
            style={{ backgroundColor: emotion.color }}
          >
            Kaydet
          </button>
        </div>
      </div>

      {/* Canvas stack */}
      <div className="flex-1 relative">
        {/* Overlay: grid/lined pattern */}
        <canvas ref={overlayRef} className="absolute inset-0 w-full h-full pointer-events-none" style={{ background: "#FAF8F4" }} />
        {/* Drawing layer */}
        <canvas
          ref={canvasRef}
          className="absolute inset-0 w-full h-full touch-none cursor-crosshair"
          style={{ background: "transparent" }}
          onMouseDown={startDraw}
          onMouseMove={draw}
          onMouseUp={endDraw}
          onMouseLeave={endDraw}
          onTouchStart={startDraw}
          onTouchMove={draw}
          onTouchEnd={endDraw}
        />
      </div>

      {/* Bottom bar */}
      <div className="px-4 py-2.5 bg-surface border-t border-rim flex items-center justify-between">
        <button onClick={onDiscard} className="text-sm text-ink-subtle hover:text-ink-muted transition-colors font-medium">
          Vazgeç
        </button>
        <div className="flex items-center gap-1.5">
          {params.palette.map((c, i) => (
            <div key={i} className="w-4 h-4 rounded-full border-2 border-white shadow-sm" style={{ backgroundColor: c }} />
          ))}
        </div>
      </div>

      {/* Save modal */}
      {showSave && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-end sm:items-center justify-center p-4">
          <div className="bg-surface rounded-[22px] w-full max-w-sm shadow-xl">
            <div className="flex items-center justify-between px-6 pt-5 pb-2">
              <div>
                <h2 className="font-bold text-ink text-lg">Çizimi Paylaş</h2>
                <p className="text-sm text-ink-subtle mt-0.5">Feed&apos;e eklenecek</p>
              </div>
              <button onClick={() => setShowSave(false)} className="p-2 rounded-[10px] text-ink-subtle hover:bg-surface-muted">
                <X size={18} />
              </button>
            </div>
            <div className="px-6 pb-6 pt-2">
              <div className="flex items-center gap-2 mb-4 p-3 bg-surface-muted rounded-[14px]">
                <span className="text-xl">{emotion.emoji}</span>
                <div>
                  <p className="text-sm font-medium text-ink">{emotion.label} · {bgLabel}</p>
                  <p className="text-xs text-ink-subtle">{bpm} BPM</p>
                </div>
              </div>
              <textarea
                value={caption} onChange={e => setCaption(e.target.value)}
                placeholder="Bir şeyler yaz… (isteğe bağlı)" rows={3}
                className="w-full px-4 py-3 rounded-[14px] bg-canvas border border-rim text-sm text-ink placeholder:text-ink-subtle focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent resize-none mb-4 transition"
              />
              <div className="flex gap-2">
                <button onClick={() => setShowSave(false)}
                  className="flex-1 py-3 rounded-[14px] text-sm font-semibold text-ink-muted bg-surface-muted hover:bg-[#EDE9E3] transition-colors">
                  İptal
                </button>
                <button onClick={handleSave} disabled={saving}
                  className="flex-1 py-3 rounded-[14px] text-sm font-semibold text-white flex items-center justify-center gap-1.5 active:scale-[0.98] disabled:opacity-60 transition-all"
                  style={{ backgroundColor: emotion.color }}>
                  {saving ? <><Loader2 size={15} className="animate-spin" />Yükleniyor…</> : <><Share2 size={15} />Paylaş</>}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function ToolButton({ onClick, label, children }: { onClick: () => void; label: string; children: React.ReactNode }) {
  return (
    <button onClick={onClick} title={label}
      className="p-2 rounded-[9px] text-ink-muted hover:bg-surface hover:text-ink hover:shadow-sm transition-all active:scale-90">
      {children}
    </button>
  )
}

// Arka plan deseni çiz
function drawBackground(ctx: CanvasRenderingContext2D, w: number, h: number, bg: BgType) {
  if (bg === "blank") return
  ctx.strokeStyle = "rgba(120, 113, 108, 0.12)"
  ctx.lineWidth = 0.5
  if (bg === "grid") {
    const step = 24
    for (let x = 0; x <= w; x += step) {
      ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke()
    }
    for (let y = 0; y <= h; y += step) {
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke()
    }
  } else if (bg === "lined") {
    const step = 28
    for (let y = step; y <= h; y += step) {
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke()
    }
    // Sol kenar çizgisi (defter efekti)
    ctx.strokeStyle = "rgba(212, 114, 63, 0.15)"
    ctx.lineWidth = 1
    ctx.beginPath(); ctx.moveTo(40, 0); ctx.lineTo(40, h); ctx.stroke()
  }
}
