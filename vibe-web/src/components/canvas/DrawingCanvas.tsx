"use client"

import { useRef, useEffect, useState, useCallback } from "react"
import { Undo2, Trash2, Download, Share2, Loader2, X, Sparkles } from "lucide-react"
import { getBrushParams, getStrokeWidth, EMOTIONS, type EmotionState } from "@/lib/drawingEngine"
import type { BgType } from "./EmotionPicker"
import { cn } from "@/lib/utils"

interface DrawingCanvasProps {
  emotion: EmotionState
  bpm: number
  bg: BgType
  bgColor: string
  onSave: (dataUrl: string, caption: string) => Promise<void>
  onDiscard: () => void
}

export function DrawingCanvas({ emotion, bpm, bg, bgColor, onSave, onDiscard }: DrawingCanvasProps) {
  const canvasRef    = useRef<HTMLCanvasElement>(null)
  const overlayRef   = useRef<HTMLCanvasElement>(null)
  const isDrawing    = useRef(false)
  const lastPos      = useRef<{ x: number; y: number } | null>(null)
  const history      = useRef<ImageData[]>([])
  const colorIndex   = useRef(0)

  const [currentEmotion, setCurrentEmotion] = useState<EmotionState>(emotion)
  const [currentBpm, setCurrentBpm]         = useState<number>(bpm)
  const [selectedColor, setSelectedColor]   = useState<string | null>(null)
  const [isEditingMood, setIsEditingMood]   = useState(false)

  const [saving, setSaving]     = useState(false)
  const [caption, setCaption]   = useState("")
  const [showSave, setShowSave] = useState(false)

  const params = getBrushParams(currentEmotion, currentBpm)

  // Reset selected color when emotion changes
  useEffect(() => {
    setSelectedColor(null)
  }, [currentEmotion])

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
    
    // Clear drawing layer (transparent by default)
    ctx.clearRect(0, 0, rect.width, rect.height)
    
    // Set contrasting text color for "Çizmeye başla…"
    const isDarkBg = isDarkColor(bgColor)
    ctx.fillStyle = isDarkBg ? "rgba(255, 255, 255, 0.35)" : "#C8C0B4"
    ctx.font = "13px system-ui"
    ctx.textAlign = "center"
    ctx.fillText("Çizmeye başla…", rect.width / 2, rect.height / 2)

    // Overlay — grid veya lined
    overlay.width  = rect.width  * dpr
    overlay.height = rect.height * dpr
    octx.scale(dpr, dpr)
    drawBackground(octx, rect.width, rect.height, bg, bgColor)
  }, [bg, bgColor])

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
    const color = selectedColor ?? params.palette[colorIndex.current % params.palette.length]
    ctx.fillStyle = color + Math.round(params.opacity * 255).toString(16).padStart(2, "0")
    ctx.fill()
  }, [params, saveHistory, selectedColor])

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
    const color = selectedColor ?? params.palette[colorIndex.current % params.palette.length]
    const alpha = Math.round(params.opacity * 255).toString(16).padStart(2, "0")
    ctx.save()
    if (params.blur > 0) {
      ctx.shadowBlur = params.blur * 2
      ctx.shadowColor = color + alpha
    }
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
  }, [params, selectedColor])

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
    ctx.clearRect(0, 0, rect.width, rect.height)
  }

  const download = () => {
    const canvas = canvasRef.current
    if (!canvas) return
    
    // Download should also merge the background color
    const merged = document.createElement("canvas")
    merged.width  = canvas.width
    merged.height = canvas.height
    const mctx = merged.getContext("2d")!
    
    mctx.fillStyle = bgColor
    mctx.fillRect(0, 0, merged.width, merged.height)
    
    const overlay = overlayRef.current
    if (overlay) {
      mctx.drawImage(overlay, 0, 0)
    }
    mctx.drawImage(canvas, 0, 0)
    
    const a = document.createElement("a")
    a.download = `vibe-${emotion.label}-${Date.now()}.png`
    a.href = merged.toDataURL("image/png")
    a.click()
  }

  const handleSave = async () => {
    const canvas  = canvasRef.current
    const overlay = overlayRef.current
    if (!canvas) return
    setSaving(true)

    // Overlay (grid/çizgili arka plan) + çizim katmanını birleştir
    const merged = document.createElement("canvas")
    merged.width  = canvas.width
    merged.height = canvas.height
    const mctx = merged.getContext("2d")!
    
    // 1. Fill with the chosen background color
    mctx.fillStyle = bgColor
    mctx.fillRect(0, 0, merged.width, merged.height)
    
    // 2. Draw background grid/lined overlay patterns (if any)
    if (overlay) {
      mctx.drawImage(overlay, 0, 0)
    }
    
    // 3. Draw the drawing strokes
    mctx.drawImage(canvas, 0, 0)
    
    const dataUrl = merged.toDataURL("image/png")

    await onSave(dataUrl, caption)
    setSaving(false)
    setShowSave(false)
  }

  const bgLabel = bg === "grid" ? "🧮 Kareli" : bg === "lined" ? "📝 Çizgili" : "📄 Boş"

  return (
    <div className="flex flex-col h-[calc(100vh-56px)]">
      {/* Top bar */}
      <div className="flex items-center justify-between px-4 py-2 bg-surface border-b border-rim gap-3">
        <button
          onClick={() => setIsEditingMood(true)}
          title="Duygu durumunu ve BPM'i değiştir"
          className="flex items-center gap-2.5 min-w-0 px-2 py-1 rounded-[12px] hover:bg-surface-muted transition active:scale-95 text-left"
        >
          <span className="text-xl shrink-0">{currentEmotion.emoji}</span>
          <div className="min-w-0">
            <p className="text-sm font-semibold text-ink leading-tight truncate flex items-center gap-1">
              <span>{currentEmotion.label}</span>
              <Sparkles size={12} className="text-accent animate-pulse" />
            </p>
            <p className="text-xs text-ink-subtle">{currentBpm} BPM · {bgLabel}</p>
          </div>
        </button>
        <div className="flex items-center gap-1.5 shrink-0">
          <div className="flex items-center gap-0.5 bg-surface-muted rounded-[12px] p-1">
            <ToolButton onClick={undo} label="Geri Al"><Undo2 size={16} /></ToolButton>
            <ToolButton onClick={clear} label="Temizle"><Trash2 size={16} /></ToolButton>
            <ToolButton onClick={download} label="İndir"><Download size={16} /></ToolButton>
          </div>
          <button
            onClick={() => setShowSave(true)}
            className="px-3.5 py-1.5 rounded-[10px] text-sm font-semibold text-white transition-all active:scale-95 shadow-sm"
            style={{ backgroundColor: currentEmotion.color }}
          >
            Kaydet
          </button>
        </div>
      </div>

      {/* Canvas stack */}
      <div className="flex-1 relative">
        {/* Overlay: grid/lined pattern */}
        <canvas ref={overlayRef} className="absolute inset-0 w-full h-full pointer-events-none" style={{ background: bgColor }} />
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
      <div className="px-4 py-2.5 bg-surface border-t border-rim flex items-center justify-between gap-4">
        <button onClick={onDiscard} className="text-xs sm:text-sm text-ink-subtle hover:text-ink-muted transition-colors font-medium">
          Vazgeç
        </button>
        
        <div className="flex items-center gap-3">
          {/* Otomatik Mod Butonu */}
          <button
            onClick={() => setSelectedColor(null)}
            className={cn(
              "px-2.5 py-1 rounded-[8px] text-[10px] sm:text-xs font-semibold transition active:scale-95 border",
              selectedColor === null
                ? "bg-accent/10 border-accent/30 text-accent"
                : "bg-surface-muted border-transparent text-ink-muted hover:text-ink"
            )}
          >
            Otomatik Ritim
          </button>

          {/* Renk Çemberleri */}
          <div className="flex items-center gap-1.5">
            {params.palette.map((c, i) => {
              const isSelected = selectedColor === c
              return (
                <button
                  key={i}
                  onClick={() => setSelectedColor(isSelected ? null : c)}
                  className={cn(
                    "w-6 h-6 rounded-full border-2 border-white shadow-sm transition active:scale-90 relative flex items-center justify-center cursor-pointer",
                    isSelected ? "ring-2 ring-accent ring-offset-1 scale-105" : "hover:scale-105"
                  )}
                  style={{ backgroundColor: c }}
                  title="Fırça rengini sabitle"
                >
                  {isSelected && (
                    <div className="w-1.5 h-1.5 rounded-full bg-white shadow-sm" />
                  )}
                </button>
              )
            })}
          </div>
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
                <span className="text-xl">{currentEmotion.emoji}</span>
                <div>
                  <p className="text-sm font-medium text-ink">{currentEmotion.label} · {bgLabel}</p>
                  <p className="text-xs text-ink-subtle">{currentBpm} BPM</p>
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
                  style={{ backgroundColor: currentEmotion.color }}>
                  {saving ? <><Loader2 size={15} className="animate-spin" />Yükleniyor…</> : <><Share2 size={15} />Paylaş</>}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Mood edit modal */}
      {isEditingMood && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-end sm:items-center justify-center p-4">
          <div className="bg-surface rounded-[22px] w-full max-w-md shadow-xl overflow-hidden">
            <div className="flex items-center justify-between px-6 pt-5 pb-2 border-b border-rim">
              <div>
                <h2 className="font-bold text-ink text-lg">Duygu Durumunu Güncelle</h2>
                <p className="text-sm text-ink-subtle mt-0.5">Fırça stili ve renk paletini etkiler</p>
              </div>
              <button onClick={() => setIsEditingMood(false)} className="p-2 rounded-[10px] text-ink-subtle hover:bg-surface-muted">
                <X size={18} />
              </button>
            </div>

            <div className="p-6">
              {/* Duygu Grid */}
              <div className="mb-6">
                <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest mb-3">Duygu</p>
                <div className="grid grid-cols-5 gap-2">
                  {EMOTIONS.map(e => {
                    const isSelected = currentEmotion.label === e.label
                    return (
                      <button
                        key={e.label}
                        onClick={() => setCurrentEmotion(e)}
                        className={cn(
                          "flex flex-col items-center gap-1 py-2 px-1 rounded-[12px] transition active:scale-95",
                          isSelected ? "scale-105" : "bg-surface-muted hover:bg-[#EDE9E3]"
                        )}
                        style={isSelected ? {
                          backgroundColor: e.color + "18",
                          border: `2px solid ${e.color}40`,
                          boxShadow: `0 2px 8px ${e.color}25`,
                        } : {}}
                      >
                        <span className="text-xl leading-none">{e.emoji}</span>
                        <span className="text-[9px] font-semibold text-ink-muted leading-tight text-center">{e.label}</span>
                      </button>
                    )
                  })}
                </div>
              </div>

              {/* BPM Slider */}
              <div className="bg-surface-muted border border-rim rounded-[18px] p-4 mb-6">
                <div className="flex items-center justify-between mb-2">
                  <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest">Kalp Atışı (BPM)</p>
                  <span className="text-sm font-bold" style={{ color: currentEmotion.color }}>
                    {currentBpm} <span className="text-[10px] font-normal text-ink-subtle">BPM</span>
                  </span>
                </div>
                <input
                  type="range" min={40} max={180} value={currentBpm}
                  onChange={e => setCurrentBpm(Number(e.target.value))}
                  className="w-full h-1.5 rounded-full appearance-none cursor-pointer"
                  style={{ accentColor: currentEmotion.color }}
                />
                <div className="flex justify-between text-[9px] text-ink-subtle mt-1.5">
                  <span>40 Sakin</span>
                  <span>Enerjik 180</span>
                </div>
              </div>

              {/* Tamamla Butonu */}
              <button
                onClick={() => setIsEditingMood(false)}
                className="w-full py-3 rounded-[14px] text-sm font-bold text-white transition active:scale-95 shadow-sm"
                style={{ backgroundColor: currentEmotion.color }}
              >
                Uygula ve Devam Et
              </button>
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
function drawBackground(ctx: CanvasRenderingContext2D, w: number, h: number, bg: BgType, bgColor: string) {
  if (bg === "blank") return
  const isDarkBg = isDarkColor(bgColor)
  ctx.strokeStyle = isDarkBg ? "rgba(255, 255, 255, 0.08)" : "rgba(120, 113, 108, 0.12)"
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
    ctx.strokeStyle = isDarkBg ? "rgba(239, 68, 68, 0.3)" : "rgba(212, 114, 63, 0.15)"
    ctx.lineWidth = 1
    ctx.beginPath(); ctx.moveTo(40, 0); ctx.lineTo(40, h); ctx.stroke()
  }
}

function isDarkColor(hex: string): boolean {
  const cleanHex = hex.replace("#", "")
  if (cleanHex.length !== 6) return false
  const r = parseInt(cleanHex.substring(0, 2), 16)
  const g = parseInt(cleanHex.substring(2, 4), 16)
  const b = parseInt(cleanHex.substring(4, 6), 16)
  const brightness = (r * 299 + g * 587 + b * 114) / 1000
  return brightness < 128
}
