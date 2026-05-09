import { cn } from "@/lib/utils"
import { ButtonHTMLAttributes, forwardRef } from "react"

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "ghost" | "danger"
  size?: "sm" | "md" | "lg"
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = "primary", size = "md", className, children, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(
          "inline-flex items-center justify-center gap-2 font-medium transition-all active:scale-95 disabled:opacity-50 disabled:pointer-events-none",
          {
            "bg-accent text-white hover:bg-accent-hover rounded-[14px]": variant === "primary",
            "bg-surface border border-rim text-ink hover:bg-surface-muted rounded-[14px]": variant === "secondary",
            "text-ink-muted hover:text-ink hover:bg-surface-muted rounded-[10px]": variant === "ghost",
            "bg-red-500 text-white hover:bg-red-600 rounded-[14px]": variant === "danger",
          },
          {
            "text-xs px-3 py-1.5": size === "sm",
            "text-sm px-4 py-2.5": size === "md",
            "text-base px-5 py-3": size === "lg",
          },
          className
        )}
        {...props}
      >
        {children}
      </button>
    )
  }
)
Button.displayName = "Button"
