"use client"

import { useState } from "react"
import { EMOTIONS, type EmotionState } from "@/lib/drawingEngine"
import { cn } from "@/lib/utils"

export type BgType = "blank" | "grid" | "lined"

const BG_OPTIONS: { value: BgType; label: string; emoji: string; desc: string }[] = [
  { value: "blank",  label: "Boş Sayfa",     emoji: "📄", desc: "Düz, sade zemin" },
  { value: "grid",   label: "Kareli Sayfa",   emoji: "🧮", desc: "Geometri & Tasarım" },
  { value: "lined",  label: "Çizgili Sayfa",  emoji: "📝", desc: "Yazı ve Notlar" },
]

interface EmotionPickerProps {
  onSelect: (emotion: EmotionState, bpm: number, bg: BgType) => void
}

export function EmotionPicker({ onSelect }: EmotionPickerProps) {
  const [selected, setSelected] = useState<EmotionState | null>(null)
  const [bpm, setBpm]           = useState(72)
  const [bg, setBg]             = useState<BgType>("blank")

  const accent = selected?.color ?? "#D9723F"

  return (
    <div className="min-h-[calc(100vh-56px)] bg-canvas">
      <div className="max-w-2xl mx-auto px-4 py-8 sm:py-12">

        {/* Başlık */}
        <div className="text-center mb-8">
          <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest mb-2">Yeni Çizim</p>
          <h1 className="text-2xl sm:text-3xl font-bold text-ink">Şu an nasıl hissediyorsun?</h1>
          <p className="text-sm text-ink-muted mt-1.5">Duygun fırçanı şekillendirir</p>
        </div>

        {/* Duygu grid */}
        <div className="bg-surface border border-rim rounded-[22px] p-5 shadow-sm mb-4">
          <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest mb-3">Duygu</p>
          <div className="grid grid-cols-5 sm:grid-cols-10 gap-2">
            {EMOTIONS.map(e => (
              <button
                key={e.label}
                onClick={() => setSelected(e)}
                className={cn(
                  "flex flex-col items-center gap-1.5 py-3 px-1 rounded-[14px] transition-all duration-150 active:scale-95",
                  selected?.label === e.label
                    ? "scale-105"
                    : "bg-surface-muted hover:bg-[#EDE9E3]"
                )}
                style={selected?.label === e.label ? {
                  backgroundColor: e.color + "18",
                  border: `2px solid ${e.color}40`,
                  boxShadow: `0 2px 8px ${e.color}25`,
                } : {}}
              >
                <span className="text-2xl leading-none">{e.emoji}</span>
                <span className="text-[9px] font-semibold text-ink-muted leading-tight text-center">{e.label}</span>
              </button>
            ))}
          </div>
        </div>

        {/* BPM + Arka Plan yan yana */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-5">
          {/* BPM */}
          <div className="bg-surface border border-rim rounded-[22px] p-5 shadow-sm">
            <div className="flex items-center justify-between mb-3">
              <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest">Kalp Atışı</p>
              <span className="text-lg font-bold tabular-nums" style={{ color: accent }}>{bpm} <span className="text-xs font-normal text-ink-subtle">BPM</span></span>
            </div>
            <input
              type="range" min={40} max={180} value={bpm}
              onChange={e => setBpm(Number(e.target.value))}
              className="w-full h-1.5 rounded-full appearance-none cursor-pointer"
              style={{ accentColor: accent }}
            />
            <div className="flex justify-between text-[10px] text-ink-subtle mt-2">
              <span>40 Sakin</span>
              <span>Enerjik 180</span>
            </div>
          </div>

          {/* Arka Plan */}
          <div className="bg-surface border border-rim rounded-[22px] p-5 shadow-sm">
            <p className="text-xs font-semibold text-ink-subtle uppercase tracking-widest mb-3">Sayfa Tipi</p>
            <div className="flex flex-col gap-2">
              {BG_OPTIONS.map(opt => (
                <button
                  key={opt.value}
                  onClick={() => setBg(opt.value)}
                  className={cn(
                    "flex items-center gap-2.5 px-3 py-2 rounded-[12px] transition-all text-left",
                    bg === opt.value
                      ? "bg-accent/10 border border-[#D9723F]/30"
                      : "bg-surface-muted hover:bg-[#EDE9E3] border border-transparent"
                  )}
                >
                  <span className="text-lg">{opt.emoji}</span>
                  <div>
                    <p className={cn("text-xs font-semibold", bg === opt.value ? "text-accent" : "text-ink")}>{opt.label}</p>
                    <p className="text-[10px] text-ink-subtle">{opt.desc}</p>
                  </div>
                  {bg === opt.value && (
                    <div className="ml-auto w-4 h-4 rounded-full bg-accent flex items-center justify-center">
                      <div className="w-1.5 h-1.5 rounded-full bg-surface" />
                    </div>
                  )}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Önizleme + Başla */}
        <div className="flex items-center gap-4">
          {selected && (
            <div
              className="w-12 h-12 rounded-[14px] flex items-center justify-center text-2xl shrink-0 shadow-sm transition-all"
              style={{ backgroundColor: selected.color + "20", border: `2px solid ${selected.color}30` }}
            >
              {selected.emoji}
            </div>
          )}
          <button
            onClick={() => selected && onSelect(selected, bpm, bg)}
            disabled={!selected}
            className="flex-1 py-3.5 rounded-[16px] text-sm font-bold transition-all active:scale-[0.98] disabled:opacity-40 disabled:cursor-not-allowed shadow-sm"
            style={selected
              ? { backgroundColor: selected.color, color: "#fff", boxShadow: `0 4px 14px ${selected.color}40` }
              : { backgroundColor: "#E8E4DC", color: "#A8A29E" }
            }
          >
            {selected ? `${selected.emoji}  Çizmeye Başla` : "Önce bir duygu seç"}
          </button>
        </div>
      </div>
    </div>
  )
}
