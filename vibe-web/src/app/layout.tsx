import type { Metadata } from "next"
import { Geist } from "next/font/google"
import "./globals.css"
import { Navbar } from "@/components/layout/Navbar"
import { ToastContainer } from "@/components/ui/Toast"

const geist = Geist({ subsets: ["latin"], variable: "--font-geist" })

export const metadata: Metadata = {
  title: "Vibe — Duyguyla Çiz",
  description: "Kalp atışınla şekillenen bir çizim deneyimi.",
  openGraph: {
    title: "Vibe",
    description: "Duyguyla çiz, paylaş.",
    type: "website",
  },
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="tr" className={`${geist.variable} h-full antialiased`}>
      <body className="min-h-full flex flex-col bg-[#FAF8F4] font-[family-name:var(--font-geist)]">
        <Navbar />
        <div className="flex-1">{children}</div>
        <ToastContainer />
      </body>
    </html>
  )
}
