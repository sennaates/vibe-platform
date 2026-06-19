import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function toDate(date: any): Date | null {
  if (!date) return null

  if (date instanceof Date) {
    return date
  }

  // If it's a Firestore Timestamp or similar object with toDate() function
  if (typeof date.toDate === "function") {
    return date.toDate()
  }

  // If it's a Firestore Timestamp parsed as a plain JSON object (e.g. from localStorage)
  if (typeof date.seconds === "number") {
    return new Date(date.seconds * 1000 + Math.floor((date.nanoseconds || 0) / 1000000))
  }
  if (typeof date._seconds === "number") {
    return new Date(date._seconds * 1000 + Math.floor((date._nanoseconds || 0) / 1000000))
  }

  // If it's a string (e.g. ISO string) or a number (millisecond timestamp)
  if (typeof date === "string" || typeof date === "number") {
    const d = new Date(date)
    return isNaN(d.getTime()) ? null : d
  }

  // Fallback parsing
  const d = new Date(date)
  return isNaN(d.getTime()) ? null : d
}

export function formatRelativeTime(date: any): string {
  const d = toDate(date)
  if (!d) return ""

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
