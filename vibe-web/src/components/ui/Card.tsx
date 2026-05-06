import { cn } from "@/lib/utils"
import { HTMLAttributes } from "react"

export function Card({ className, children, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        "bg-white border border-[#E8E4DC] rounded-[18px] overflow-hidden",
        className
      )}
      {...props}
    >
      {children}
    </div>
  )
}
