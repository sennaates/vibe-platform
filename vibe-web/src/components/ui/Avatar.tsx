import { profileColors } from "@/lib/design"
import { cn } from "@/lib/utils"

interface AvatarProps {
  emoji: string
  color: string
  size?: "sm" | "md" | "lg" | "xl"
  className?: string
}

const sizes = {
  sm: "w-7 h-7 text-sm",
  md: "w-9 h-9 text-base",
  lg: "w-12 h-12 text-xl",
  xl: "w-16 h-16 text-2xl",
}

export function Avatar({ emoji, color, size = "md", className }: AvatarProps) {
  const bg = profileColors[color] ?? "#4A7FA5"

  return (
    <div
      className={cn(
        "rounded-full flex items-center justify-center shrink-0",
        sizes[size],
        className
      )}
      style={{ backgroundColor: bg + "28" }}
    >
      <span>{emoji}</span>
    </div>
  )
}
