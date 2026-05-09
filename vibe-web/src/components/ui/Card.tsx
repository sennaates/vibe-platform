import { cn } from "@/lib/utils"
import { HTMLAttributes } from "react"

export function Card({ className, children, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        "bg-surface border border-rim rounded-[18px] overflow-hidden",
        className
      )}
      {...props}
    >
      {children}
    </div>
  )
}
