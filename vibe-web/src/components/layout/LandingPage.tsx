"use client"

import { useRef, useEffect, useState, useCallback } from "react"
import Image from "next/image"
import Link from "next/link"
import { Sparkles, Heart, Activity, Palette, Share2, BarChart2, Trash2 } from "lucide-react"
import { EMOTIONS, getBrushParams, getStrokeWidth, type EmotionState } from "@/lib/drawingEngine"

export function LandingPage() {
  // Simulator state
  const [selectedEmotion, setSelectedEmotion] = useState<EmotionState>(EMOTIONS[1]) // Default to "Mutlu"
  const [bpm, setBpm] = useState(80)

  const canvasRef = useRef<HTMLCanvasElement>(null)
  const isDrawing = useRef(false)
  const lastPos = useRef<{ x: number; y: number } | null>(null)
  const colorIndex = useRef(0)

  // Get active brush parameters
  const brushParams = getBrushParams(selectedEmotion, bpm)

  // Reset/Initialize Canvas size
  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext("2d")
    if (!ctx) return

    const dpr = window.devicePixelRatio || 1
    const rect = canvas.getBoundingClientRect()
    canvas.width = rect.width * dpr
    canvas.height = rect.height * dpr
    ctx.scale(dpr, dpr)
    
    // Background style
    ctx.fillStyle = "#FAF8F4"
    ctx.fillRect(0, 0, rect.width, rect.height)

    // Initial instruction text
    ctx.fillStyle = "#A8A29E"
    ctx.font = "14px system-ui, sans-serif"
    ctx.textAlign = "center"
    ctx.fillText("Fırçayı denemek için buraya çizin...", rect.width / 2, rect.height / 2)
  }, [])

  const getPos = (e: React.MouseEvent | React.TouchEvent) => {
    const canvas = canvasRef.current
    if (!canvas) return { x: 0, y: 0 }
    const rect = canvas.getBoundingClientRect()
    if ("touches" in e) {
      const touch = e.touches[0]
      return { x: touch.clientX - rect.left, y: touch.clientY - rect.top }
    }
    return { x: (e as React.MouseEvent).clientX - rect.left, y: (e as React.MouseEvent).clientY - rect.top }
  }

  const startDraw = useCallback((e: React.MouseEvent | React.TouchEvent) => {
    e.preventDefault()
    const canvas = canvasRef.current
    const ctx = canvas?.getContext("2d")
    if (!canvas || !ctx) return

    // Clear instruction text on first click
    if (colorIndex.current === 0) {
      const rect = canvas.getBoundingClientRect()
      ctx.fillStyle = "#FAF8F4"
      ctx.fillRect(0, 0, rect.width, rect.height)
    }

    isDrawing.current = true
    const pos = getPos(e)
    lastPos.current = pos

    ctx.beginPath()
    ctx.arc(pos.x, pos.y, brushParams.minWidth / 2, 0, Math.PI * 2)
    const color = brushParams.palette[colorIndex.current % brushParams.palette.length]
    ctx.fillStyle = color + Math.round(brushParams.opacity * 255).toString(16).padStart(2, "0")
    ctx.fill()
  }, [brushParams])

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
    
    if (speed > 12) colorIndex.current++

    const width = getStrokeWidth(brushParams, dx, dy)
    const color = brushParams.palette[colorIndex.current % brushParams.palette.length]
    const alpha = Math.round(brushParams.opacity * 255).toString(16).padStart(2, "0")

    ctx.save()
    if (brushParams.blur > 0) {
      ctx.shadowBlur = brushParams.blur * 2
      ctx.shadowColor = color + alpha
    }
    ctx.strokeStyle = color + alpha
    ctx.lineWidth = width
    ctx.lineCap = "round"
    ctx.lineJoin = "round"

    if (brushParams.strokeStyle === "sketchy") {
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
  }, [brushParams])

  const endDraw = useCallback(() => {
    isDrawing.current = false
    lastPos.current = null
  }, [])

  const clearCanvas = () => {
    const canvas = canvasRef.current
    const ctx = canvas?.getContext("2d")
    if (!canvas || !ctx) return
    const rect = canvas.getBoundingClientRect()
    ctx.fillStyle = "#FAF8F4"
    ctx.fillRect(0, 0, rect.width, rect.height)
  }

  return (
    <div className="bg-canvas min-h-screen flex flex-col text-ink antialiased">
      
      {/* 1. Centered Hero Section */}
      <section className="relative overflow-hidden py-20 sm:py-32 border-b border-rim/60 bg-gradient-to-b from-surface/20 via-surface/40 to-canvas">
        {/* Modern Dot Background Pattern */}
        <div className="absolute inset-0 bg-[radial-gradient(var(--rim)_1.5px,transparent_1.5px)] bg-[size:32px_32px] opacity-40 pointer-events-none" />
        
        {/* Animated fluid background gradients */}
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] sm:w-[900px] h-[400px] sm:h-[600px] bg-gradient-to-tr from-accent/15 via-orange-500/10 to-pink-500/15 rounded-full blur-[120px] sm:blur-[180px] animate-pulse pointer-events-none" />
        
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 relative text-center space-y-8">
          {/* Logo Badge (Centered) */}
          <div className="flex justify-center">
            <div className="relative group transition-transform duration-300 hover:scale-105 select-none">
              <div className="absolute -inset-1 bg-gradient-to-r from-accent via-orange-500 to-pink-500 rounded-[22px] blur-sm opacity-60 group-hover:opacity-100 transition duration-1000 group-hover:duration-200 animate-pulse pointer-events-none" />
              <div className="relative flex items-center gap-3.5 px-6 py-3 bg-surface/85 dark:bg-surface/90 backdrop-blur-md border border-rim/60 rounded-[20px] shadow-md">
                <div className="w-10 h-10 rounded-xl overflow-hidden shadow-inner shrink-0 relative border border-rim/40 group-hover:animate-heartbeat transition-transform duration-300">
                  <Image src="/logo.png" alt="Vibe Logo" fill className="object-cover" />
                </div>
                <div className="text-left">
                  <p className="font-black text-ink text-base tracking-tight leading-none flex items-center gap-1.5">
                    Vibe
                    <Sparkles size={13} className="text-amber-500 fill-current animate-pulse shrink-0" />
                  </p>
                  <span className="text-[10px] font-bold text-accent tracking-widest uppercase mt-1 block">Duygu & Ritim</span>
                </div>
              </div>
            </div>
          </div>
          
          <h1 className="text-4xl sm:text-6xl lg:text-7xl font-extrabold tracking-tight leading-[1.08] max-w-3xl mx-auto">
            Ruhunun Renkleri ve <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-accent via-orange-500 to-pink-500 drop-shadow-sm font-black">
              Kalbinin Ritmiyle Çiz
            </span>
          </h1>
          
          <p className="text-base sm:text-xl text-ink-muted max-w-2xl mx-auto leading-relaxed">
            Vibe, iç dünyanızı ve duygularınızı tuvale döken büyülü bir dijital sanat alanıdır. Kalp atışınız fırçanın vuruşuna yön verirken, hissettiğiniz her duygu benzersiz renk paletleriyle hayat bulur. Kendinizi ritmin akışına bırakın.
          </p>
          
          {/* Action buttons (Centered) */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <Link
              href="/auth"
              className="w-full sm:w-auto px-10 py-4 bg-accent text-white rounded-[18px] text-base font-bold shadow-lg shadow-accent/20 hover:shadow-xl hover:shadow-accent/30 hover:-translate-y-0.5 active:translate-y-0 active:scale-[0.98] transition-all flex items-center justify-center gap-2 group"
            >
              <Activity size={18} className="group-hover:animate-pulse" />
              Hemen Çizmeye Başla
            </Link>
            <Link
              href="/auth"
              className="w-full sm:w-auto px-10 py-4 bg-surface/60 backdrop-blur-md border border-rim text-ink font-semibold rounded-[18px] text-base hover:bg-surface-muted hover:-translate-y-0.5 active:translate-y-0 transition-all flex items-center justify-center"
            >
              Giriş Yap / Üye Ol
            </Link>
          </div>
        </div>
      </section>

      {/* 2. Interactive Brush Simulator Section */}
      <section className="py-20 sm:py-28 border-b border-rim/60 bg-surface/30 relative">
        <div className="absolute inset-0 bg-[radial-gradient(var(--rim)_1.2px,transparent_1.2px)] bg-[size:48px_48px] opacity-15 pointer-events-none" />
        
        {/* Dynamic color blob trailing the selected emotion */}
        <div 
          className="absolute right-1/4 top-1/4 w-[400px] h-[400px] rounded-full blur-[160px] opacity-10 transition-all duration-1000 pointer-events-none"
          style={{ backgroundColor: selectedEmotion.color }}
        />

        <div className="max-w-7xl mx-auto px-4 sm:px-6 relative z-10">
          <div className="text-center max-w-2xl mx-auto mb-16 space-y-3">
            <p className="text-xs font-semibold text-accent uppercase tracking-widest">Çevrimiçi Deneyim</p>
            <h2 className="text-3xl sm:text-4xl font-extrabold text-ink">Dijital Fırçanı Keşfet</h2>
            <p className="text-sm sm:text-base text-ink-muted leading-relaxed">
              Giriş yapmadan önce Vibe çizim motorunu deneyimleyin. Bir duygu seçip kalp ritminizi ayarlayın ve tuvale dokunun.
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-stretch">
            
            {/* Left Col - Controls (5/12 cols) */}
            <div className="lg:col-span-5 flex flex-col gap-6">
              
              {/* Emotion Selector - Refined Circular Cards */}
              <div className="bg-surface/70 backdrop-blur-md border border-rim/60 rounded-[28px] p-6 shadow-sm space-y-4">
                <div className="flex items-center justify-between">
                  <p className="text-xs font-extrabold text-ink-subtle uppercase tracking-widest">1. Duygu Modunu Seç</p>
                  <span className="text-[10px] font-bold text-ink-muted bg-surface-muted px-2.5 py-0.5 rounded-full uppercase tracking-wider">{selectedEmotion.label}</span>
                </div>
                <div className="grid grid-cols-5 gap-3">
                  {EMOTIONS.slice(0, 10).map(e => {
                    const isSelected = selectedEmotion.label === e.label
                    return (
                      <button
                        key={e.label}
                        onClick={() => setSelectedEmotion(e)}
                        className={`group relative flex flex-col items-center gap-1.5 py-3 px-1 rounded-[16px] transition-all duration-300 active:scale-95 border ${
                          isSelected
                            ? "shadow-md scale-105"
                            : "border-transparent bg-surface-muted/50 hover:bg-surface-muted hover:scale-102"
                        }`}
                        style={{
                          borderColor: isSelected ? `${e.color}50` : undefined,
                          backgroundColor: isSelected ? `${e.color}10` : undefined,
                          boxShadow: isSelected ? `0 6px 20px ${e.color}15` : undefined
                        }}
                      >
                        {/* Selected Indicator Glow */}
                        {isSelected && (
                          <div 
                            className="absolute inset-0 rounded-[16px] blur-sm opacity-50"
                            style={{ border: `2.5px solid ${e.color}` }}
                          />
                        )}
                        <span className="text-2xl transition-transform duration-300 group-hover:scale-110">{e.emoji}</span>
                        <span className="text-[9px] font-extrabold text-ink-muted text-center truncate w-full group-hover:text-ink">{e.label}</span>
                      </button>
                    )
                  })}
                </div>
              </div>

              {/* Heart rate & BPM slider */}
              <div 
                className="bg-surface/70 backdrop-blur-md border rounded-[28px] p-6 shadow-sm transition-all duration-500 relative overflow-hidden group/bpm"
                style={{ 
                  borderColor: `${selectedEmotion.color}40`,
                  boxShadow: `0 10px 30px ${selectedEmotion.color}08`, 
                  background: `linear-gradient(135deg, var(--surface) 0%, ${selectedEmotion.color}08 100%)`
                }}
              >
                <div className="flex items-center justify-between mb-4 relative z-10" style={{ '--bpm-duration': `${60 / bpm}s` } as React.CSSProperties}>
                  <div className="flex items-center gap-2 select-none">
                    <p className="text-xs font-bold text-ink-subtle uppercase tracking-widest">2. Kalp Ritmini Ayarla</p>
                    {/* Bouncing EKG waves */}
                    <div className="flex items-end gap-[2px] h-3.5 shrink-0 mb-[1px]">
                      {[0.4, 0.9, 0.5, 0.8, 0.3].map((val, idx) => (
                        <span
                          key={idx}
                          className="w-[2.5px] rounded-full origin-bottom animate-bpm-bounce"
                          style={{
                            backgroundColor: selectedEmotion.color,
                            height: `${val * 100}%`,
                            animationDelay: `${idx * 0.15}s`
                          }}
                        />
                      ))}
                    </div>
                  </div>

                  <span 
                    className="text-xs font-extrabold flex items-center gap-2 px-3.5 py-1.5 bg-surface-muted rounded-full border shadow-inner select-none transition-all duration-300"
                    style={{ 
                      color: selectedEmotion.color,
                      borderColor: `${selectedEmotion.color}25`
                    }}
                  >
                    <span className="relative flex h-3.5 w-3.5 items-center justify-center shrink-0">
                      <span 
                        className="absolute inline-flex h-full w-full rounded-full bg-current opacity-60 animate-bpm-ripple"
                      ></span>
                      <Heart 
                        size={13} 
                        className="relative inline-flex fill-current text-current animate-bpm-pulse"
                      />
                    </span>
                    <span className="tabular-nums text-xs">{bpm} BPM</span>
                  </span>
                </div>

                <div className="relative my-5 z-10 flex items-center">
                  <input
                    type="range"
                    min={40}
                    max={180}
                    value={bpm}
                    onChange={e => setBpm(Number(e.target.value))}
                    className="w-full h-2.5 rounded-full appearance-none cursor-pointer transition-all duration-300 focus:outline-none"
                    style={{ 
                      background: `linear-gradient(to right, ${selectedEmotion.color} 0%, ${selectedEmotion.color} ${((bpm - 40) / (180 - 40)) * 100}%, var(--rim) ${((bpm - 40) / (180 - 40)) * 100}%, var(--rim) 100%)`,
                      accentColor: selectedEmotion.color
                    }}
                  />
                </div>

                <div className="flex justify-between text-[9px] font-bold text-ink-subtle mt-1 relative z-10">
                  <span className="transition-colors duration-300" style={{ color: bpm < 80 ? selectedEmotion.color : undefined }}>40 Sakin</span>
                  <span className="transition-colors duration-300" style={{ color: bpm >= 80 && bpm <= 130 ? selectedEmotion.color : undefined }}>110 Ritmik</span>
                  <span className="transition-colors duration-300" style={{ color: bpm > 130 ? selectedEmotion.color : undefined }}>180 Enerjik</span>
                </div>
              </div>

              {/* Active Brush Instrument Panel */}
              <div 
                className="bg-surface/70 backdrop-blur-md border rounded-[28px] p-6 shadow-sm flex-1 flex flex-col justify-center transition-all duration-500 relative overflow-hidden"
                style={{ 
                  boxShadow: `inset 0 0 30px ${selectedEmotion.color}05`,
                  borderColor: `${selectedEmotion.color}25`
                }}
              >
                <p className="text-xs font-bold text-ink-subtle uppercase tracking-widest mb-4">Aktif Fırça Stili</p>
                <div className="grid grid-cols-2 gap-y-4 gap-x-6 text-xs sm:text-sm">
                  <div className="space-y-1">
                    <span className="text-ink-subtle text-[10px] block font-bold uppercase tracking-wider">Fırça Tipi:</span>
                    <span className="font-bold capitalize text-ink flex items-center gap-1.5">
                      {brushParams.strokeStyle === "sketchy" ? "Karalama ✏️" : brushParams.strokeStyle === "smooth" ? "Yumuşak 🌊" : "İşaretçi 🖊️"}
                    </span>
                  </div>
                  <div className="space-y-1">
                    <span className="text-ink-subtle text-[10px] block font-bold uppercase tracking-wider">Boyut Aralığı:</span>
                    <span className="font-bold text-ink">{Math.round(brushParams.minWidth)}px – {Math.round(brushParams.maxWidth)}px</span>
                  </div>
                  <div className="space-y-1">
                    <span className="text-ink-subtle text-[10px] block font-bold uppercase tracking-wider">Opaklık (Valence):</span>
                    <span className="font-bold text-ink">%{Math.round(brushParams.opacity * 100)}</span>
                  </div>
                  <div className="space-y-1">
                    <span className="text-ink-subtle text-[10px] block font-bold uppercase tracking-wider">Yumuşatma (Blur):</span>
                    <span className="font-bold text-ink">{brushParams.blur > 0 ? `${brushParams.blur}px` : "Yok"}</span>
                  </div>
                </div>
              </div>

            </div>

            {/* Sandbox Canvas (7/12 cols) with Glowing Frame */}
            <div className="lg:col-span-7 flex flex-col">
              <div 
                className="relative border bg-[#FAF8F4] rounded-[32px] overflow-hidden shadow-xl flex-1 min-h-[400px] transition-all duration-500 group/canvas"
                style={{ 
                  boxShadow: `0 15px 40px ${selectedEmotion.color}18`, 
                  borderColor: `${selectedEmotion.color}50`,
                  borderWidth: "2px"
                }}
              >
                <canvas
                  ref={canvasRef}
                  className="absolute inset-0 w-full h-full touch-none cursor-crosshair"
                  onMouseDown={startDraw}
                  onMouseMove={draw}
                  onMouseUp={endDraw}
                  onMouseLeave={endDraw}
                  onTouchStart={startDraw}
                  onTouchMove={draw}
                  onTouchEnd={endDraw}
                />
                
                {/* Floating controls in Sandbox */}
                <div className="absolute top-4 left-4 right-4 flex items-center justify-between pointer-events-none select-none z-10">
                  <div className="flex items-center gap-2 px-3.5 py-2 bg-surface/80 backdrop-blur-md border border-rim/60 rounded-xl text-xs font-semibold text-ink shadow-sm pointer-events-auto">
                    <Palette size={13} style={{ color: selectedEmotion.color }} />
                    <span>Tuval Modu</span>
                  </div>
                  
                  <button
                    onClick={clearCanvas}
                    title="Temizle"
                    className="p-2.5 rounded-xl bg-surface border border-rim hover:bg-surface-muted text-ink-muted active:scale-95 transition-all shadow-sm pointer-events-auto"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
            </div>

          </div>
        </div>
      </section>

      {/* 3. Features Grid */}
      <section className="py-20 sm:py-28 border-b border-rim/60 relative">
        <div className="absolute inset-0 bg-[radial-gradient(var(--rim)_1.2px,transparent_1.2px)] bg-[size:40px_40px] opacity-20 pointer-events-none" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          
          <div className="text-center max-w-2xl mx-auto mb-16 space-y-3">
            <p className="text-xs font-semibold text-accent uppercase tracking-widest">Özellikler</p>
            <h2 className="text-3xl sm:text-4xl font-extrabold text-ink">Sanatın Kalp Atışlarınla Şekillensin</h2>
            <p className="text-sm text-ink-muted">Vibe, duygularınızı dijital bir fırçayla birleştiren eşsiz özelliklere sahiptir.</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <FeatureCard
              icon={<Heart className="text-red-400" />}
              title="Ritim Odaklı Fırçalar"
              desc="Kalp atış hızınız (BPM) fırça kalınlığını, karalama efektini ve fırça yumuşaklığını doğrudan kontrol eder."
              gradient="from-red-400 to-pink-500"
            />
            <FeatureCard
              icon={<Palette className="text-amber-500" />}
              title="Duygu Paletleri"
              desc="10 farklı duygu modu için özel olarak optimize edilmiş, hissinizi yansıtan renk paletleriyle boyayın."
              gradient="from-amber-400 to-orange-500"
            />
            <FeatureCard
              icon={<Share2 className="text-indigo-400" />}
              title="Sosyal Paylaşım"
              desc="Çizimlerinizi Vibe topluluğuyla paylaşın, başkalarının gönderilerini beğenin ve duygu dolu yorumlar yazın."
              gradient="from-indigo-400 to-purple-500"
            />
            <FeatureCard
              icon={<BarChart2 className="text-emerald-500" />}
              title="Kişisel Analizler"
              desc="Aktivite haritası, BPM geçmişi ve duygu dağılımları ile duygusal durumunuzu haftalık takip edin."
              gradient="from-emerald-400 to-teal-500"
            />
          </div>

        </div>
      </section>

      {/* 4. Footer */}
      <footer className="py-12 bg-surface/30 border-t border-rim/40 text-center space-y-4">
        <p className="text-sm text-ink-subtle">© {new Date().getFullYear()} Vibe. Tüm hakları saklıdır.</p>
        <div className="flex justify-center gap-4 text-xs font-medium text-ink-muted">
          <Link href="/auth" className="hover:underline">Hemen Başla</Link>
          <span>·</span>
          <Link href="/auth" className="hover:underline">Giriş Yap</Link>
        </div>
      </footer>

    </div>
  )
}

function FeatureCard({ icon, title, desc, gradient }: { icon: React.ReactNode; title: string; desc: string; gradient: string }) {
  return (
    <div className="bg-surface/60 backdrop-blur-sm border border-rim/80 rounded-[22px] p-6 shadow-sm hover:shadow-lg hover:-translate-y-1.5 transition-all duration-300 flex flex-col gap-4 relative overflow-hidden group">
      {/* Dynamic background glow on hover */}
      <div className={`absolute inset-0 bg-gradient-to-b ${gradient} opacity-0 group-hover:opacity-[0.03] transition-opacity duration-300 pointer-events-none`} />
      
      {/* Top indicator line */}
      <div className={`absolute top-0 left-0 right-0 h-1.5 bg-gradient-to-r ${gradient} group-hover:h-2 transition-all duration-300`} />
      
      <div className="w-10 h-10 rounded-[14px] bg-surface-muted dark:bg-surface-muted/30 flex items-center justify-center transition-all duration-300 group-hover:scale-110 group-hover:bg-surface-muted/80">
        {icon}
      </div>
      <div>
        <h3 className="font-bold text-ink text-base mb-1.5 group-hover:text-transparent group-hover:bg-clip-text group-hover:bg-gradient-to-r group-hover:from-accent group-hover:to-pink-500 transition-colors duration-300">{title}</h3>
        <p className="text-xs sm:text-sm text-ink-muted leading-relaxed">{desc}</p>
      </div>
    </div>
  )
}
