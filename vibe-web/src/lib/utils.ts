import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatRelativeTime(date: Date | { toDate(): Date } | string): string {
  const d = typeof date === "string"
    ? new Date(date)
    : "toDate" in date
      ? date.toDate()
      : date

  const diff = Date.now() - d.getTime()
  const mins  = Math.floor(diff / 60_000)
  const hours = Math.floor(diff / 3_600_000)
  const days  = Math.floor(diff / 86_400_000)

  if (mins < 1)   return "şimdi"
  if (mins < 60)  return `${mins}d`
  if (hours < 24) return `${hours}s`
  if (days < 7)   return `${days}g`
  return d.toLocaleDateString("tr-TR", { day: "numeric", month: "short" })
}
