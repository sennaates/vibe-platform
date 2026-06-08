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
  const [isDrawing, setIsDrawing] = useState(false)

  const canvasRef = useRef<HTMLCanvasElement>(null)
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

    setIsDrawing(true)
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
    if (!isDrawing || !lastPos.current) return
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
    if (brushParams.blur > 0) ctx.filter = `blur(${brushParams.blur}px)`
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
  }, [isDrawing, brushParams])

  const endDraw = useCallback(() => {
    setIsDrawing(false)
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
      
      {/* 1. Hero Section */}
      <section className="relative overflow-hidden py-16 sm:py-24 border-b border-rim/60 bg-gradient-to-b from-surface/20 to-canvas">
        {/* Modern Dot Background Pattern */}
        <div className="absolute inset-0 bg-[radial-gradient(var(--rim)_1.5px,transparent_1.5px)] bg-[size:32px_32px] opacity-40 pointer-events-none" />
        
        {/* Animated Background Gradients */}
        <div className="absolute top-1/4 left-1/4 w-[300px] sm:w-[500px] h-[300px] sm:h-[500px] bg-gradient-to-br from-accent/12 to-orange-500/8 rounded-full blur-[100px] sm:blur-[140px] animate-pulse pointer-events-none" />
        <div className="absolute bottom-1/3 right-1/4 w-[350px] sm:w-[550px] h-[350px] sm:h-[550px] bg-gradient-to-tr from-pink-500/12 to-indigo-500/8 rounded-full blur-[120px] sm:blur-[160px] animate-pulse pointer-events-none" style={{ animationDelay: "3s" }} />
        
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
            
            {/* Left Col - Copy */}
            <div className="lg:col-span-7 space-y-6 sm:space-y-8 text-center lg:text-left">
              {/* Premium Glow Logo Badge */}
              <div className="flex justify-center lg:justify-start">
                <div className="relative group transition-transform duration-300 hover:scale-105 select-none">
                  <div className="absolute -inset-1 bg-gradient-to-r from-accent via-orange-500 to-pink-500 rounded-[22px] blur-sm opacity-60 group-hover:opacity-100 transition duration-1000 group-hover:duration-200 animate-pulse pointer-events-none" />
                  <div className="relative flex items-center gap-3.5 px-5 py-3 bg-surface/90 dark:bg-surface/95 backdrop-blur-md border border-rim/60 rounded-[18px] shadow-md">
                    <div className="w-10 h-10 rounded-xl overflow-hidden shadow-inner shrink-0 relative border border-rim/40 group-hover:scale-105 group-hover:animate-heartbeat transition-transform duration-300">
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
              
              <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight leading-[1.12]">
                Duyguların ve Kalp Ritmin <br />
                <span className="text-transparent bg-clip-text bg-gradient-to-r from-accent via-orange-500 to-pink-500 drop-shadow-sm font-black">
                  Sanata Dönüşsün
                </span>
              </h1>
              
              <p className="text-base sm:text-lg text-ink-muted max-w-xl mx-auto lg:mx-0 leading-relaxed">
                Vibe, kalp atış hızınızla (BPM) ve seçtiğiniz anlık duygularla fırçasını şekillendiren benzersiz bir çizim deneyimidir. Hızınız, renginiz ve stiliniz ritminizle belirlenir.
              </p>
              
              <div className="flex flex-col sm:flex-row gap-3 justify-center lg:justify-start">
                <Link
                  href="/auth"
                  className="px-8 py-3.5 bg-accent text-white rounded-[16px] text-sm font-bold shadow-md hover:bg-accent-hover active:scale-[0.98] transition-all flex items-center justify-center gap-2"
                >
                  <Activity size={16} />
                  Hemen Çizmeye Başla
                </Link>
                <Link
                  href="/auth"
                  className="px-8 py-3.5 bg-surface border border-rim text-ink font-semibold rounded-[16px] text-sm hover:bg-surface-muted transition-all flex items-center justify-center"
                >
                  Giriş Yap / Üye Ol
                </Link>
              </div>
            </div>
            
            {/* Right Col - Premium Image with Floating Badge */}
            <div className="lg:col-span-5 flex justify-center">
              <div className="relative p-2.5 bg-surface/40 backdrop-blur-md border border-rim/80 rounded-[32px] shadow-xl overflow-hidden max-w-[400px] w-full aspect-square group">
                {/* Glowing aura around image */}
                <div className="absolute -inset-10 bg-gradient-to-tr from-accent/30 via-orange-500/10 to-pink-500/20 rounded-[50px] blur-3xl opacity-50 group-hover:opacity-80 transition duration-1000 group-hover:duration-500 pointer-events-none" />
                <div className="absolute inset-0 bg-gradient-to-tr from-accent/20 to-pink-500/10 opacity-0 group-hover:opacity-100 transition-opacity duration-500 z-10 pointer-events-none" />
                
                <div className="w-full h-full relative rounded-[22px] overflow-hidden border border-rim/50 z-0 bg-surface">
                  <Image
                    src="/vibe_landing_hero.png"
                    alt="Vibe Art Concept"
                    fill
                    priority
                    sizes="(max-width: 1024px) 100vw, 40vw"
                    className="object-cover group-hover:scale-105 transition-transform duration-700"
                  />
                </div>

                {/* Floating status badge on the image */}
                <div className="absolute bottom-6 left-6 right-6 bg-surface/85 dark:bg-surface/90 backdrop-blur-md border border-rim/60 rounded-2xl p-3 shadow-lg flex items-center justify-between transform translate-y-2 group-hover:translate-y-0 opacity-95 group-hover:opacity-100 transition-all duration-500 z-20 select-none">
                  <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-full bg-accent/10 dark:bg-accent/20 flex items-center justify-center text-accent">
                      <Heart size={14} className="fill-current animate-heartbeat" />
                    </div>
                    <div className="text-left">
                      <p className="text-[10px] font-medium text-ink-subtle leading-none">Ritim Senkronu</p>
                      <p className="text-xs font-bold text-ink mt-0.5">120 BPM • Mutlu</p>
                    </div>
                  </div>
                  <span className="text-[10px] font-bold text-accent px-2 py-1 bg-accent/8 border border-accent/20 rounded-lg">Çizim Aktif</span>
                </div>
              </div>
            </div>
            
          </div>
        </div>
      </section>

      {/* 2. Interactive Brush Simulator */}
      <section className="py-16 sm:py-24 border-b border-rim/60 bg-surface/30 relative">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 relative z-10">
          <div className="text-center max-w-2xl mx-auto mb-12">
            <h2 className="text-2xl sm:text-3xl font-extrabold text-ink">Fırça Simülatörü</h2>
            <p className="text-sm sm:text-base text-ink-muted mt-2">
              Giriş yapmadan önce Vibe çizim motorunu deneyimleyin. Bir duygu seçin ve kalp ritminizi değiştirip test edin!
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-stretch">
            
            {/* Simulator Controls (5/12 cols) */}
            <div className="lg:col-span-5 flex flex-col gap-5 justify-between">
              
              {/* Emotion Selector */}
              <div className="bg-surface border border-rim/80 rounded-[24px] p-5 shadow-sm">
                <p className="text-xs font-bold text-ink-subtle uppercase tracking-widest mb-3">1. Duygu Seç</p>
                <div className="grid grid-cols-5 gap-2">
                  {EMOTIONS.slice(0, 10).map(e => (
                    <button
                      key={e.label}
                      onClick={() => setSelectedEmotion(e)}
                      className={`flex flex-col items-center gap-1 py-2 px-1 rounded-[12px] transition-all duration-150 active:scale-95 border ${
                        selectedEmotion.label === e.label
                          ? "border-accent/40 bg-accent/8 scale-105"
                          : "border-transparent bg-surface-muted hover:bg-[#EDE9E3]"
                      }`}
                      style={selectedEmotion.label === e.label ? { borderColor: e.color + "50", backgroundColor: e.color + "12" } : {}}
                    >
                      <span className="text-xl">{e.emoji}</span>
                      <span className="text-[9px] font-bold text-ink-muted text-center truncate w-full">{e.label}</span>
                    </button>
                  ))}
                </div>
              </div>

              {/* BPM Slider with Dynamic Sound Wave Pulse */}
              <div 
                className="bg-surface border rounded-[24px] p-5 shadow-sm transition-all duration-500 overflow-hidden relative group/bpm"
                style={{ 
                  borderColor: `${selectedEmotion.color}40`,
                  boxShadow: `0 8px 30px ${selectedEmotion.color}08`, 
                  background: `linear-gradient(135deg, var(--surface) 0%, ${selectedEmotion.color}06 100%)`
                }}
              >
                {/* Ambient dynamic color blob inside the card */}
                <div 
                  className="absolute -right-10 -bottom-10 w-24 h-24 rounded-full blur-[40px] opacity-15 transition-all duration-500 pointer-events-none group-hover/bpm:scale-150"
                  style={{ backgroundColor: selectedEmotion.color }}
                />

                <div className="flex items-center justify-between mb-3 relative z-10">
                  <div className="flex items-center gap-2 select-none" style={{ '--bpm-duration': `${60 / bpm}s` } as React.CSSProperties}>
                    <p className="text-xs font-bold text-ink-subtle uppercase tracking-widest">2. Kalp Ritmini Ayarla</p>
                    {/* Bouncing EKG waves */}
                    <div className="flex items-end gap-[2px] h-3.5 shrink-0 mb-[1px]">
                      {[0.4, 0.9, 0.5, 0.8, 0.3].map((val, idx) => (
                        <span
                          key={idx}
                          className="w-[2px] rounded-full animate-bpm-bounce origin-bottom"
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
                    className="text-xs font-extrabold flex items-center gap-2 px-3 py-1 bg-surface-muted rounded-full border border-rim/60 shadow-inner select-none transition-all duration-300"
                    style={{ 
                      color: selectedEmotion.color,
                      borderColor: `${selectedEmotion.color}25`,
                      "--bpm-duration": `${60 / bpm}s`
                    } as React.CSSProperties}
                  >
                    <span className="relative flex h-3.5 w-3.5 items-center justify-center shrink-0">
                      <span className="animate-bpm-ripple absolute inline-flex h-full w-full rounded-full bg-current opacity-60"></span>
                      <Heart size={13} className="animate-bpm-pulse relative inline-flex fill-current text-current" />
                    </span>
                    <span className="tabular-nums text-xs">{bpm} BPM</span>
                  </span>
                </div>

                <div className="relative my-4 z-10 flex items-center">
                  <input
                    type="range"
                    min={40}
                    max={180}
                    value={bpm}
                    onChange={e => setBpm(Number(e.target.value))}
                    className="w-full h-2 rounded-full appearance-none cursor-pointer transition-all duration-300 focus:outline-none"
                    style={{ 
                      background: `linear-gradient(to right, ${selectedEmotion.color} 0%, ${selectedEmotion.color} ${((bpm - 40) / (180 - 40)) * 100}%, var(--rim) ${((bpm - 40) / (180 - 40)) * 100}%, var(--rim) 100%)`,
                      accentColor: selectedEmotion.color
                    }}
                  />
                </div>

                <div className="flex justify-between text-[9px] font-bold text-ink-subtle mt-1.5 relative z-10">
                  <span className="transition-colors duration-300" style={{ color: bpm < 80 ? selectedEmotion.color : undefined }}>40 Sakin</span>
                  <span className="transition-colors duration-300" style={{ color: bpm >= 80 && bpm <= 130 ? selectedEmotion.color : undefined }}>110 Ritmik</span>
                  <span className="transition-colors duration-300" style={{ color: bpm > 130 ? selectedEmotion.color : undefined }}>180 Enerjik</span>
                </div>
              </div>

              {/* Active Brush Stats with Dynamic Aura */}
              <div 
                className="bg-surface border border-rim/80 rounded-[24px] p-5 shadow-sm flex-1 flex flex-col justify-center transition-all duration-500"
                style={{ 
                  boxShadow: `inset 0 0 20px ${selectedEmotion.color}05`,
                  borderColor: `${selectedEmotion.color}25`
                }}
              >
                <p className="text-xs font-bold text-ink-subtle uppercase tracking-widest mb-3">Aktif Fırça Stili</p>
                <div className="grid grid-cols-2 gap-4 text-xs">
                  <div>
                    <span className="text-ink-subtle block">Fırça Tipi:</span>
                    <span className="font-semibold capitalize text-ink">
                      {brushParams.strokeStyle === "sketchy" ? "Karalama ✏️" : brushParams.strokeStyle === "smooth" ? "Yumuşak 🌊" : "İşaretçi 🖊️"}
                    </span>
                  </div>
                  <div>
                    <span className="text-ink-subtle block">Boyut Aralığı:</span>
                    <span className="font-semibold text-ink">{Math.round(brushParams.minWidth)}px – {Math.round(brushParams.maxWidth)}px</span>
                  </div>
                  <div>
                    <span className="text-ink-subtle block">Opaklık (Valence):</span>
                    <span className="font-semibold text-ink">%{Math.round(brushParams.opacity * 100)}</span>
                  </div>
                  <div>
                    <span className="text-ink-subtle block">Yumuşatma (Blur):</span>
                    <span className="font-semibold text-ink">{brushParams.blur > 0 ? `${brushParams.blur}px` : "Yok"}</span>
                  </div>
                </div>
              </div>
              
            </div>

            {/* Sandbox Canvas (7/12 cols) with Dynamic Glow Border */}
            <div className="lg:col-span-7 flex flex-col gap-2">
              <div 
                className="relative border bg-[#FAF8F4] rounded-[24px] overflow-hidden shadow-lg flex-1 min-h-[350px] transition-all duration-500"
                style={{ 
                  boxShadow: `0 10px 30px ${selectedEmotion.color}15`, 
                  borderColor: `${selectedEmotion.color}40`,
                  borderWidth: "1.5px"
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
                <button
                  onClick={clearCanvas}
                  title="Temizle"
                  className="absolute bottom-4 right-4 p-2.5 rounded-[12px] bg-surface border border-rim hover:bg-surface-muted text-ink-muted active:scale-95 transition-all shadow-sm z-10"
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </div>

          </div>
        </div>
      </section>

      {/* 3. Features Grid */}
      <section className="py-16 sm:py-24 border-b border-rim/60 relative">
        <div className="absolute inset-0 bg-[radial-gradient(var(--rim)_1.2px,transparent_1.2px)] bg-[size:40px_40px] opacity-20 pointer-events-none" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          
          <div className="text-center max-w-2xl mx-auto mb-16">
            <p className="text-xs font-semibold text-accent uppercase tracking-widest mb-1.5">Özellikler</p>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-ink">Sanatın Kalp Atışlarınla Şekillensin</h2>
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

      {/* 4. Footer CTA */}
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
