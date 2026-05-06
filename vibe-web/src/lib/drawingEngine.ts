// Vibe Drawing Engine — iOS DrawingEngine.swift ile eşleşir
// Duygu → fırça parametreleri mapping

export interface EmotionState {
  label: string
  emoji: string
  valence: number  // -1..1 (negatif→pozitif)
  arousal: number  // -1..1 (sakin→enerjik)
  color: string
}

export const EMOTIONS: EmotionState[] = [
  { label: "Sakin",     emoji: "🌊", valence:  0.6, arousal: -0.6, color: "#4A7FA5" },
  { label: "Mutlu",     emoji: "☀️", valence:  0.9, arousal:  0.4, color: "#D9A23F" },
  { label: "Enerjik",   emoji: "⚡", valence:  0.5, arousal:  0.9, color: "#D9723F" },
  { label: "Heyecanlı", emoji: "🔥", valence:  0.7, arousal:  0.8, color: "#C0504A" },
  { label: "Kaygılı",   emoji: "😰", valence: -0.5, arousal:  0.8, color: "#7C5CBF" },
  { label: "Stresli",   emoji: "💢", valence: -0.7, arousal:  0.9, color: "#8B3A3A" },
  { label: "Üzgün",     emoji: "🌧️", valence: -0.8, arousal: -0.5, color: "#556B8B" },
  { label: "Yorgun",    emoji: "🌙", valence: -0.2, arousal: -0.8, color: "#6B7280" },
  { label: "Huzurlu",   emoji: "🌸", valence:  0.8, arousal: -0.3, color: "#C45F8A" },
  { label: "Odaklanmış",emoji: "🎯", valence:  0.3, arousal:  0.2, color: "#3A8FA0" },
]

export interface BrushParams {
  minWidth: number
  maxWidth: number
  opacity: number
  blur: number
  color: string
  palette: string[]
  strokeStyle: "smooth" | "sketchy" | "marker"
}

export function getBrushParams(emotion: EmotionState, bpm: number): BrushParams {
  const { valence, arousal } = emotion

  // BPM normalize (60-180 → 0-1)
  const bpmNorm = Math.min(Math.max((bpm - 60) / 120, 0), 1)
  const energy = (arousal + 1) / 2 * 0.7 + bpmNorm * 0.3

  // Enerjik → kalın/hızlı, sakin → ince/yumuşak
  const minWidth = 1 + (1 - energy) * 4
  const maxWidth = 4 + energy * 20

  // Pozitif valence → şeffaf/açık, negatif → opak/koyu
  const opacity = valence > 0
    ? 0.45 + valence * 0.35
    : 0.65 + Math.abs(valence) * 0.25

  // Sakin → blur, stresli → net
  const blur = energy < 0.3 ? 1.5 : energy > 0.7 ? 0 : 0.5

  // Stil
  const strokeStyle: BrushParams["strokeStyle"] =
    energy > 0.7 ? "sketchy" :
    arousal < -0.3 ? "smooth" : "marker"

  // Palet — valence/arousal bazlı
  const palette = buildPalette(emotion)

  return { minWidth, maxWidth, opacity, blur, color: emotion.color, palette, strokeStyle }
}

function buildPalette(emotion: EmotionState): string[] {
  const { valence, arousal } = emotion
  if (valence > 0.6 && arousal > 0.5)
    return ["#F4A261","#E76F51","#E9C46A","#F7D08A","#FFB347"]
  if (valence > 0.6 && arousal <= 0.5)
    return ["#A8DADC","#457B9D","#B7E4C7","#74C69D","#95D5B2"]
  if (valence <= -0.5 && arousal > 0.5)
    return ["#6D2B2B","#8B3A3A","#5C4033","#3D2B2B","#2D1B1B"]
  if (valence <= -0.5 && arousal <= 0)
    return ["#4A5568","#718096","#A0AEC0","#CBD5E0","#2D3748"]
  return [emotion.color, "#D9723F","#4A7FA5","#7C5CBF","#4A9B6F"]
}

// Hız bazlı çizgi genişliği hesapla
export function getStrokeWidth(
  params: BrushParams,
  dx: number,
  dy: number
): number {
  const speed = Math.sqrt(dx * dx + dy * dy)
  const t = Math.min(speed / 30, 1)
  // Hız arttıkça ince (kalem etkisi)
  return params.maxWidth - (params.maxWidth - params.minWidth) * t
}
