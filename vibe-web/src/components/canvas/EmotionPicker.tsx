"use client"

import { useState } from "react"
import { EMOTIONS, type EmotionState } from "@/lib/drawingEngine"
import { cn } from "@/lib/utils"

interface EmotionPickerProps {
  onSelect: (emotion: EmotionState, bpm: number) => void
}

export function EmotionPicker({ onSelect }: EmotionPickerProps) {
  const [selected, setSelected] = useState<EmotionState | null>(null)
  const [bpm, setBpm] = useState(72)

  const accentColor = selected?.color ?? "#D9723F"

  return (
    <div className="flex flex-col items-center justify-center min-h-[calc(100vh-56px)] px-4 py-10 bg-[#FAF8F4]">
      <div className="w-full max-w-md">

        {/* Title block */}
        <div className="text-center mb-8">
          <p className="text-xs font-semibold text-[#A8A29E] uppercase tracking-widest mb-2">Canvas</p>
          <h1 className="text-2xl font-bold text-[#1C1917] leading-tight">
            Şu an nasıl hissediyorsun?
          </h1>
          <p className="text-sm text-[#78716C] mt-2">
            Duygun fırçanı şekillendirir
          </p>
        </div>

        {/* Emotion grid — 5 columns */}
        <div className="grid grid-cols-5 gap-2 mb-5">
          {EMOTIONS.map(e => {
            const isSelected = selected?.label === e.label
            return (
              <button
                key={e.label}
                onClick={() => setSelected(e)}
                className={cn(
                  "flex flex-col items-center gap-1.5 py-3.5 px-1 rounded-[14px] transition-all duration-150 border",
                  isSelected
                    ? "scale-105 shadow-sm"
                    : "bg-white border-[#E8E4DC] hover:border-[#C8C0B4] hover:shadow-sm active:scale-95"
                )}
                style={
                  isSelected
                    ? {
                        backgroundColor: e.color + "15",
                        borderColor: e.color,
                        borderWidth: "2px",
                      }
                    : {}
                }
              >
                <span className="text-3xl leading-none">{e.emoji}</span>
                <span
                  className="text-[10px] font-medium leading-tight text-center"
                  style={{ color: isSelected ? e.color : "#78716C" }}
                >
                  {e.label}
                </span>
              </button>
            )
          })}
        </div>

        {/* BPM slider card */}
        <div className="bg-white border border-[#E8E4DC] rounded-[18px] p-5 mb-5 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-sm font-semibold text-[#1C1917]">Kalp Atışı</p>
              <p className="text-xs text-[#A8A29E] mt-0.5">Çizim hızını etkiler</p>
            </div>
            <div
              className="text-2xl font-bold tabular-nums transition-colors"
              style={{ color: accentColor }}
            >
              {bpm}
              <span className="text-sm font-medium ml-0.5">bpm</span>
            </div>
          </div>

          <input
            type="range"
            min={40}
            max={180}
            value={bpm}
            onChange={e => setBpm(Number(e.target.value))}
            className="w-full h-1.5 rounded-full appearance-none cursor-pointer"
            style={{
              background: `linear-gradient(to right, ${accentColor} 0%, ${accentColor} ${((bpm - 40) / 140) * 100}%, #E8E4DC ${((bpm - 40) / 140) * 100}%, #E8E4DC 100%)`,
              accentColor: accentColor,
            }}
          />
          <div className="flex justify-between text-[10px] text-[#A8A29E] mt-2 font-medium">
            <span>Sakin · 40</span>
            <span>180 · Enerjik</span>
          </div>
        </div>

        {/* CTA */}
        <button
          onClick={() => selected && onSelect(selected, bpm)}
          disabled={!selected}
          className={cn(
            "w-full py-4 rounded-[14px] text-base font-semibold text-white transition-all duration-200",
            selected
              ? "shadow-sm active:scale-[0.98] hover:brightness-105"
              : "bg-[#E8E4DC] text-[#A8A29E] cursor-not-allowed"
          )}
          style={selected ? { backgroundColor: accentColor } : {}}
        >
          {selected
            ? `${selected.emoji}  Çizmeye Başla`
            : "Bir duygu seç"}
        </button>

      </div>
    </div>
  )
}
