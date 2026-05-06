"use client"

import { useRef, useEffect, useState, useCallback } from "react"
import { Undo2, Trash2, Download, Share2, Loader2, X } from "lucide-react"
import { getBrushParams, getStrokeWidth, type EmotionState } from "@/lib/drawingEngine"

interface DrawingCanvasProps {
  emotion: EmotionState
  bpm: number
  onSave: (dataUrl: string, caption: string) => Promise<void>
  onDiscard: () => void
}

export function DrawingCanvas({ emotion, bpm, onSave, onDiscard }: DrawingCanvasProps) {
  const canvasRef  = useRef<HTMLCanvasElement>(null)
  const isDrawing  = useRef(false)
  const lastPos    = useRef<{ x: number; y: number } | null>(null)
  const history    = useRef<ImageData[]>([])
  const colorIndex = useRef(0)

  const [saving, setSaving]     = useState(false)
  const [caption, setCaption]   = useState("")
  const [showSave, setShowSave] = useState(false)

  const params = getBrushParams(emotion, bpm)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext("2d")
    if (!ctx) return

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
  }, [])

  const getPos = (e: React.MouseEvent | React.TouchEvent) => {
    const canvas = canvasRef.current!
    const rect = canvas.getBoundingClientRect()
    if ("touches" in e) {
      const touch = e.touches[0]
      return { x: touch.clientX - rect.left, y: touch.clientY - rect.top }
    }
    return {
      x: (e as React.MouseEvent).clientX - rect.left,
      y: (e as React.MouseEvent).clientY - rect.top,
    }
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
    const prev = history.current.pop()!
    ctx.putImageData(prev, 0, 0)
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
    const dataUrl = canvas.toDataURL("image/png")
    await onSave(dataUrl, caption)
    setSaving(false)
    setShowSave(false)
  }

  return (
    <div className="flex flex-col h-[calc(100vh-56px)]">

      {/* Top bar */}
      <div className="flex items-center justify-between px-4 py-2 bg-white border-b border-[#E8E4DC]">
        {/* Emotion info */}
        <div className="flex items-center gap-2.5">
          <span className="text-2xl">{emotion.emoji}</span>
          <div>
            <p className="text-sm font-semibold text-[#1C1917] leading-tight">{emotion.label}</p>
            <p className="text-xs text-[#A8A29E]">{bpm} BPM</p>
          </div>
        </div>

        {/* Tool buttons in a pill container */}
        <div className="flex items-center gap-1">
          {/* Ghost tool buttons */}
          <div className="flex items-center gap-0.5 bg-[#F5F3EF] rounded-[12px] p-1">
            <ToolButton onClick={undo} label="Geri Al">
              <Undo2 size={16} />
            </ToolButton>
            <ToolButton onClick={clear} label="Temizle">
              <Trash2 size={16} />
            </ToolButton>
            <ToolButton onClick={download} label="İndir">
              <Download size={16} />
            </ToolButton>
          </div>

          {/* Save / share button */}
          <button
            onClick={() => setShowSave(true)}
            className="ml-2 px-3.5 py-1.5 rounded-[10px] text-sm font-semibold text-white transition-all active:scale-95 shadow-sm"
            style={{ backgroundColor: emotion.color }}
          >
            Kaydet
          </button>
        </div>
      </div>

      {/* Canvas */}
      <canvas
        ref={canvasRef}
        className="flex-1 w-full touch-none cursor-crosshair"
        style={{ background: "#FAF8F4" }}
        onMouseDown={startDraw}
        onMouseMove={draw}
        onMouseUp={endDraw}
        onMouseLeave={endDraw}
        onTouchStart={startDraw}
        onTouchMove={draw}
        onTouchEnd={endDraw}
      />

      {/* Bottom bar — color swatches + discard */}
      <div className="px-4 py-2.5 bg-white border-t border-[#E8E4DC] flex items-center justify-between">
        <button
          onClick={onDiscard}
          className="text-sm text-[#A8A29E] hover:text-[#78716C] transition-colors font-medium"
        >
          Vazgeç
        </button>

        {/* Palette swatches */}
        <div className="flex items-center gap-1.5">
          {params.palette.map((c, i) => (
            <div
              key={i}
              className="w-5 h-5 rounded-full border-2 border-white shadow-sm"
              style={{ backgroundColor: c }}
            />
          ))}
        </div>
      </div>

      {/* Save / share bottom sheet */}
      {showSave && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-end sm:items-center justify-center p-4">
          <div className="bg-white rounded-[22px] w-full max-w-sm shadow-xl">
            {/* Handle / header */}
            <div className="flex items-center justify-between px-6 pt-5 pb-2">
              <div>
                <h2 className="font-bold text-[#1C1917] text-lg">Çizimi Paylaş</h2>
                <p className="text-sm text-[#A8A29E] mt-0.5">Feed&apos;e eklenecek</p>
              </div>
              <button
                onClick={() => setShowSave(false)}
                className="p-2 rounded-[10px] text-[#A8A29E] hover:bg-[#F5F3EF] transition-colors"
              >
                <X size={18} />
              </button>
            </div>

            <div className="px-6 pb-6 pt-3">
              {/* Emotion tag */}
              <div className="flex items-center gap-2 mb-4 p-3 bg-[#F5F3EF] rounded-[14px]">
                <span className="text-xl">{emotion.emoji}</span>
                <div>
                  <p className="text-sm font-medium text-[#1C1917]">{emotion.label}</p>
                  <p className="text-xs text-[#A8A29E]">{bpm} BPM</p>
                </div>
              </div>

              <textarea
                value={caption}
                onChange={e => setCaption(e.target.value)}
                placeholder="Bir şeyler yaz… (isteğe bağlı)"
                rows={3}
                className="w-full px-4 py-3 rounded-[14px] bg-[#FAF8F4] border border-[#E8E4DC] text-sm text-[#1C1917] placeholder:text-[#A8A29E] focus:outline-none focus:ring-2 focus:ring-[#D9723F]/20 focus:border-[#D9723F] resize-none mb-4 transition"
              />

              <div className="flex gap-2">
                <button
                  onClick={() => setShowSave(false)}
                  className="flex-1 py-3 rounded-[14px] text-sm font-semibold text-[#78716C] bg-[#F5F3EF] hover:bg-[#EDE9E3] transition-colors"
                >
                  İptal
                </button>
                <button
                  onClick={handleSave}
                  disabled={saving}
                  className="flex-1 py-3 rounded-[14px] text-sm font-semibold text-white flex items-center justify-center gap-1.5 transition-all active:scale-[0.98] disabled:opacity-60"
                  style={{ backgroundColor: emotion.color }}
                >
                  {saving ? (
                    <>
                      <Loader2 size={15} className="animate-spin" />
                      Yükleniyor…
                    </>
                  ) : (
                    <>
                      <Share2 size={15} />
                      Paylaş
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function ToolButton({
  onClick,
  label,
  children,
}: {
  onClick: () => void
  label: string
  children: React.ReactNode
}) {
  return (
    <button
      onClick={onClick}
      title={label}
      className="p-2 rounded-[9px] text-[#78716C] hover:bg-white hover:text-[#1C1917] hover:shadow-sm transition-all active:scale-90"
    >
      {children}
    </button>
  )
}
